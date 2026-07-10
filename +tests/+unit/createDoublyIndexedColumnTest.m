classdef createDoublyIndexedColumnTest < tests.abstract.NwbTestCase
% createDoublyIndexedColumnTest - Unit tests for util.create_doubly_indexed_column

    methods (TestClassSetup)
        function setupClass(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testSingleElectrodeShortcut(testCase)
            % Matrix-per-row form: each row's [nSpikes x nSamples] matrix, one
            % waveform per spike (single electrode).
            nSamples = 4;
            unit1 = reshape(1:(3*nSamples), 3, nSamples);         % 3 spikes
            unit2 = 100 + reshape(1:(4*nSamples), 4, nSamples);   % 4 spikes

            [vector, index, indexIndex] = ...
                util.create_doubly_indexed_column({unit1, unit2}, 'waveforms');

            % Data: samples along dim 1, one column per waveform (7 total).
            testCase.verifyEqual(size(vector.data), [nSamples, 7]);
            testCase.verifyEqual(vector.data(:, 1), unit1(1, :).');
            testCase.verifyEqual(vector.data(:, 4), unit2(1, :).');

            % Inner index: one entry per spike event (single waveform each).
            testCase.verifyEqual(index.data, uint64((1:7)'));
            % Outer index: one entry per unit (cumulative spike counts).
            testCase.verifyEqual(indexIndex.data, uint64([3; 7]));

            % Targets are wired: index -> vector, indexIndex -> index.
            testCase.verifySameHandle(index.target.target, vector);
            testCase.verifySameHandle(indexIndex.target.target, index);
        end

        function testNDArrayShortcut(testCase)
            % The first dimension is the subgroup axis; trailing dimensions are
            % preserved as the fixed element payload.
            unit1 = reshape(1:(2*3*4), 2, 3, 4);
            unit2 = 100 + reshape(1:(1*3*4), 1, 3, 4);

            [vector, index, indexIndex] = ...
                util.create_doubly_indexed_column({unit1, unit2}, 'volumes');

            testCase.verifyEqual(size(vector.data), [4, 3, 3]);
            testCase.verifyEqual(vector.data(:, :, 1), reshape(unit1(1, :, :), 3, 4).');
            testCase.verifyEqual(vector.data(:, :, 3), reshape(unit2(1, :, :), 3, 4).');
            testCase.verifyEqual(index.data, uint64((1:3)'));
            testCase.verifyEqual(indexIndex.data, uint64([2; 3]));
        end

        function testGeneralNestedCell(testCase)
            % Cell-per-row form: DATA{i}{j} is [nElements x nSamples].
            nSamples = 4;
            % unit1: event1 has 2 electrodes, event2 has 1 electrode
            % unit2: event1 has 3 electrodes
            unit1 = {ones(2, nSamples), 2 * ones(1, nSamples)};
            unit2 = {3 * ones(3, nSamples)};

            [vector, index, indexIndex] = ...
                util.create_doubly_indexed_column({unit1, unit2});

            testCase.verifyEqual(size(vector.data), [nSamples, 6]);
            % Inner index counts elements (electrodes) per sub-group: 2, 1, 3.
            testCase.verifyEqual(index.data, uint64([2; 3; 6]));
            % Outer index counts sub-groups per row: 2, 1.
            testCase.verifyEqual(indexIndex.data, uint64([2; 3]));
        end

        function testNDArrayNestedCell(testCase)
            % Cell-per-row form supports arbitrary trailing element dimensions.
            unit1 = {reshape(1:(2*3*4), 2, 3, 4), ...
                100 + reshape(1:(1*3*4), 1, 3, 4)};
            unit2 = {200 + reshape(1:(3*3*4), 3, 3, 4)};

            [vector, index, indexIndex] = ...
                util.create_doubly_indexed_column({unit1, unit2});

            testCase.verifyEqual(size(vector.data), [4, 3, 6]);
            testCase.verifyEqual(vector.data(:, :, 1), reshape(unit1{1}(1, :, :), 3, 4).');
            testCase.verifyEqual(vector.data(:, :, 3), reshape(unit1{2}(1, :, :), 3, 4).');
            testCase.verifyEqual(vector.data(:, :, 6), reshape(unit2{1}(3, :, :), 3, 4).');
            testCase.verifyEqual(index.data, uint64([2; 3; 6]));
            testCase.verifyEqual(indexIndex.data, uint64([2; 3]));
        end

        function testNDArrayExportKeepsSchemaDimensionOrder(testCase)
            unit1 = {reshape(1:(2*3*4), 2, 3, 4), ...
                100 + reshape(1:(1*3*4), 1, 3, 4)};
            unit2 = {200 + reshape(1:(3*3*4), 3, 3, 4)};

            vector = util.create_doubly_indexed_column({unit1, unit2});

            fileName = testCase.getRandomFilename();
            fileId = H5F.create(fileName);
            cleanup = onCleanup(@() H5F.close(fileId));
            io.writeDataset(fileId, '/wf', vector.data);
            delete(cleanup)

            fileId = H5F.open(fileName, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
            fileCleanup = onCleanup(@() H5F.close(fileId));
            datasetId = H5D.open(fileId, '/wf');
            datasetCleanup = onCleanup(@() H5D.close(datasetId));
            spaceId = H5D.get_space(datasetId);
            spaceCleanup = onCleanup(@() H5S.close(spaceId));
            [~, h5Dimensions, ~] = H5S.get_simple_extent_dims(spaceId);
            testCase.verifyEqual(h5Dimensions, [6, 3, 4]);
            delete(spaceCleanup)
            delete(datasetCleanup)
            delete(fileCleanup)
        end

        function testEmptyRow(testCase)
            % A row with no sub-groups is represented by [] (or {}).
            nSamples = 4;
            unit1 = reshape(1:(2*nSamples), 2, nSamples);
            unit3 = reshape(1:(3*nSamples), 3, nSamples);

            [vector, index, indexIndex] = ...
                util.create_doubly_indexed_column({unit1, [], unit3});

            testCase.verifyEqual(size(vector.data), [nSamples, 5]);
            testCase.verifyEqual(index.data, uint64((1:5)'));
            % Middle (empty) unit repeats the previous cumulative value.
            testCase.verifyEqual(indexIndex.data, uint64([2; 2; 5]));
        end

        function testInconsistentSampleLengthErrors(testCase)
            testCase.verifyError( ...
                @() util.create_doubly_indexed_column({ones(3, 4), ones(2, 5)}), ...
                'NWB:CreateDoublyIndexedColumn:InconsistentSampleLength');
        end

        function testInvalidRowTypeErrors(testCase)
            testCase.verifyError( ...
                @() util.create_doubly_indexed_column({ones(3, 4), "not numeric"}), ...
                'NWB:CreateDoublyIndexedColumn:InvalidRow');
        end

        function testRoundTripInUnitsTable(testCase)
            % Build a Units table with the doubly-indexed waveforms column,
            % export, read back, and verify the on-disk index structure.
            nSamples = 4;
            unit1 = reshape(1:(3*nSamples), 3, nSamples);
            unit2 = 100 + reshape(1:(4*nSamples), 4, nSamples);

            [vector, index, indexIndex] = ...
                util.create_doubly_indexed_column({unit1, unit2}, 'spike waveforms');

            units = types.core.Units( ...
                'colnames', {'waveforms'}, ...
                'description', 'units', ...
                'waveforms', vector, ...
                'waveforms_index', index, ...
                'waveforms_index_index', indexIndex, ...
                'id', types.hdmf_common.ElementIdentifiers('data', [0; 1]));

            nwb = NwbFile( ...
                'identifier', 'doubly_indexed_test', ...
                'session_description', 'test', ...
                'session_start_time', datetime(2024, 1, 1, 'TimeZone', 'local'));
            nwb.units = units;

            fileName = testCase.getRandomFilename();
            nwbExport(nwb, fileName);

            back = nwbRead(fileName, 'ignorecache');
            testCase.verifyEqual(back.units.waveforms_index.data.load(), uint64((1:7)'));
            testCase.verifyEqual(back.units.waveforms_index_index.data.load(), uint64([3; 7]));
        end
    end
end
