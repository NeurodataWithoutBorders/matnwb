classdef createIndexedColumnTest < tests.abstract.NwbTestCase
% createIndexedColumnTest - Unit tests for util.create_indexed_column

    methods (TestClassSetup)
        function setupClass(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testRowVectors(testCase)
            [vector, index] = util.create_indexed_column({[1 2 3], [4 5]}, 'spike times');

            testCase.verifyEqual(vector.data, [1; 2; 3; 4; 5]);
            testCase.verifyEqual(index.data, uint64([3; 5]));
            testCase.verifyEqual(vector.description, 'spike times');
            testCase.verifySameHandle(index.target.target, vector);
        end

        function testColumnVectorsMatchRowVectors(testCase)
            % Orientation of a vector row does not matter: both are lists of scalars.
            [fromRows, indexFromRows] = util.create_indexed_column({[1 2 3], [4 5]});
            [fromColumns, indexFromColumns] = util.create_indexed_column({[1; 2; 3], [4; 5]});

            testCase.verifyEqual(fromColumns.data, fromRows.data);
            testCase.verifyEqual(indexFromColumns.data, indexFromRows.data);
        end

        function testEmptyRow(testCase)
            [vector, index] = util.create_indexed_column({[1 2], [], 3});

            testCase.verifyEqual(vector.data, [1; 2; 3]);
            % The empty row repeats the previous cumulative count.
            testCase.verifyEqual(index.data, uint64([2; 2; 3]));
        end

        function testMatrixRows(testCase)
            % Elements are 4-sample vectors, one per column, as in VectorData.data.
            row1 = reshape(1:8, 4, 2);          % 2 elements
            row2 = 100 + reshape(1:12, 4, 3);   % 3 elements

            [vector, index] = util.create_indexed_column({row1, row2});

            testCase.verifyEqual(size(vector.data), [4, 5]);
            testCase.verifyEqual(vector.data(:, 1:2), row1);
            testCase.verifyEqual(vector.data(:, 3:5), row2);
            testCase.verifyEqual(index.data, uint64([2; 5]));
        end

        function testNDRows(testCase)
            % HDMF's DynamicTable.add_row stores the rows (2,3,4) and (1,3,4) of
            % an indexed column as data (3,3,4) with index [2 3] (hdmf 6.2.0).
            % With the ragged axis last, the MatNWB rows are [4x3x2] and [4x3x1],
            % and the data is [4x3x3], which is (3,3,4) on disk.
            row1 = reshape(1:24, 4, 3, 2);
            row2 = 100 + reshape(1:12, 4, 3);   % one element; MATLAB drops the trailing 1

            [vector, index] = util.create_indexed_column({row1, row2});

            testCase.verifyEqual(size(vector.data), [4, 3, 3]);
            testCase.verifyEqual(vector.data(:, :, 1:2), row1);
            testCase.verifyEqual(vector.data(:, :, 3), row2);
            testCase.verifyEqual(index.data, uint64([2; 3]));
        end

        function testSingleElementColumnVectorAmongMatrixRows(testCase)
            row1 = reshape(1:8, 4, 2);
            row2 = (101:104)';   % one 4-sample element

            [vector, index] = util.create_indexed_column({row1, row2});

            testCase.verifyEqual(vector.data(:, 3), row2);
            testCase.verifyEqual(index.data, uint64([2; 3]));
        end

        function testSingleElementRowInAnyOrder(testCase)
            % Elements [4 x 3]: the single-element row [4 x 3] is read the same
            % whether or not a fuller row precedes it.
            oneElement = reshape(1:12, 4, 3);
            twoElements = 100 + reshape(1:24, 4, 3, 2);

            [vector, index] = util.create_indexed_column({oneElement, twoElements});

            testCase.verifyEqual(size(vector.data), [4, 3, 3]);
            testCase.verifyEqual(vector.data(:, :, 1), oneElement);
            testCase.verifyEqual(index.data, uint64([1; 3]));

            [vector, index] = util.create_indexed_column({twoElements, oneElement});

            testCase.verifyEqual(vector.data(:, :, 3), oneElement);
            testCase.verifyEqual(index.data, uint64([2; 3]));
        end

        function testInconsistentElementShapeErrors(testCase)
            testCase.verifyError( ...
                @() util.create_indexed_column({ones(4, 2), ones(5, 2)}), ...
                'NWB:CreateIndexedColumn:InconsistentElementShape');
            % A row vector is not one 4-sample element; that is [4 x 1].
            testCase.verifyError( ...
                @() util.create_indexed_column({ones(4, 2), ones(1, 4)}), ...
                'NWB:CreateIndexedColumn:InconsistentElementShape');
        end

        function testInvalidRowTypeErrors(testCase)
            testCase.verifyError( ...
                @() util.create_indexed_column({[1 2], "text"}), ...
                'NWB:CreateIndexedColumn:InvalidRow');
        end

        function testTableRegion(testCase)
            target = types.hdmf_common.DynamicTable( ...
                'description', 'target', ...
                'colnames', {'x'}, ...
                'x', types.hdmf_common.VectorData('description', 'x', 'data', (1:5)'), ...
                'id', types.hdmf_common.ElementIdentifiers('data', (0:4)'));

            [region, index] = util.create_indexed_column({[0 1], [2 3 4]}, 'regions', target);

            testCase.verifyClass(region, 'types.hdmf_common.DynamicTableRegion');
            % The region validator casts the row indices to an integer class.
            testCase.verifyEqual(double(region.data), [0; 1; 2; 3; 4]);
            testCase.verifyEqual(index.data, uint64([2; 5]));
        end

        function testDepth2SingleElementShortcut(testCase)
            % Depth 2 with a matrix per row: [num_samples x num_waveforms], one
            % waveform per spike event, as for spike sorting on one electrode.
            numSamples = 4;
            unit1 = reshape(1:(3*numSamples), numSamples, 3);         % 3 spike events
            unit2 = 100 + reshape(1:(4*numSamples), numSamples, 4);   % 4 spike events

            [vector, index, indexIndex] = ...
                util.create_indexed_column({unit1, unit2}, 'waveforms', 'Depth', 2);

            testCase.verifyEqual(size(vector.data), [numSamples, 7]);
            testCase.verifyEqual(vector.data(:, 1:3), unit1);
            testCase.verifyEqual(vector.data(:, 4:7), unit2);
            testCase.verifyEqual(index.data, uint64((1:7)'));
            testCase.verifyEqual(indexIndex.data, uint64([3; 7]));
            testCase.verifySameHandle(index.target.target, vector);
            testCase.verifySameHandle(indexIndex.target.target, index);
        end

        function testDepth2FixedCountShortcut(testCase)
            % [num_samples x num_electrodes x num_spike_events] per row. HDMF's
            % DynamicTable.add_row stores the same rows, given in its own order
            % as (2,3,4) and (3,3,4), as data (15, 4) with index [3 6 9 12 15]
            % and index_index [2 5] (hdmf 6.2.0).
            unit1 = reshape(1:(4*3*2), 4, 3, 2);
            unit2 = 100 + reshape(1:(4*3*3), 4, 3, 3);

            [vector, index, indexIndex] = ...
                util.create_indexed_column({unit1, unit2}, 'Depth', 2);

            testCase.verifyEqual(size(vector.data), [4, 15]);
            % Column k holds electrode e of spike event s, with k = (s-1)*3 + e.
            testCase.verifyEqual(vector.data(:, 1), unit1(:, 1, 1));
            testCase.verifyEqual(vector.data(:, 6), unit1(:, 3, 2));
            testCase.verifyEqual(vector.data(:, 7), unit2(:, 1, 1));
            testCase.verifyEqual(index.data, uint64([3; 6; 9; 12; 15]));
            testCase.verifyEqual(indexIndex.data, uint64([2; 5]));
        end

        function testDepth2FixedCountEqualsCellForm(testCase)
            unit1 = rand(2, 4, 3);   % [num_samples x num_electrodes x num_spike_events]
            unit2 = rand(2, 4, 2);
            cellForm = {splitSpikeEvents(unit1), splitSpikeEvents(unit2)};

            [vectorA, indexA, indexIndexA] = ...
                util.create_indexed_column({unit1, unit2}, 'Depth', 2);
            [vectorB, indexB, indexIndexB] = ...
                util.create_indexed_column(cellForm, 'Depth', 2);

            testCase.verifyEqual(vectorA.data, vectorB.data);
            testCase.verifyEqual(indexA.data, indexB.data);
            testCase.verifyEqual(indexIndexA.data, indexIndexB.data);
        end

        function testDepth2NestedCell(testCase)
            % data{row}{subGroup} = [num_samples x nElements]; the element count
            % may differ between sub-groups.
            numSamples = 4;
            unit1 = {ones(numSamples, 2), 2 * ones(numSamples, 1)};   % 2 then 1 electrode
            unit2 = {3 * ones(numSamples, 3)};

            [vector, index, indexIndex] = ...
                util.create_indexed_column({unit1, unit2}, 'Depth', 2);

            testCase.verifyEqual(size(vector.data), [numSamples, 6]);
            testCase.verifyEqual(index.data, uint64([2; 3; 6]));
            testCase.verifyEqual(indexIndex.data, uint64([2; 3]));
        end

        function testDepth2NDElements(testCase)
            % Elements with more than one dimension keep their shape; the
            % ragged axis stays last.
            unit1 = {reshape(1:(4*5*2), 4, 5, 2), 100 + reshape(1:(4*5), 4, 5)};   % 2 then 1 element
            unit2 = {200 + reshape(1:(4*5*3), 4, 5, 3)};

            [vector, index, indexIndex] = ...
                util.create_indexed_column({unit1, unit2}, 'Depth', 2);

            testCase.verifyEqual(size(vector.data), [4, 5, 6]);
            testCase.verifyEqual(vector.data(:, :, 3), unit1{2});
            testCase.verifyEqual(vector.data(:, :, 6), unit2{1}(:, :, 3));
            testCase.verifyEqual(index.data, uint64([2; 3; 6]));
            testCase.verifyEqual(indexIndex.data, uint64([2; 3]));
        end

        function testDepth2EmptyRow(testCase)
            numSamples = 4;
            unit1 = reshape(1:(2*numSamples), numSamples, 2);
            unit3 = reshape(1:(3*numSamples), numSamples, 3);

            [vector, index, indexIndex] = ...
                util.create_indexed_column({unit1, [], unit3}, 'Depth', 2);

            testCase.verifyEqual(size(vector.data), [numSamples, 5]);
            testCase.verifyEqual(index.data, uint64((1:5)'));
            testCase.verifyEqual(indexIndex.data, uint64([2; 2; 5]));
        end

        function testDepth2EmptySubGroupsInArrayRow(testCase)
            % [num_samples x 0 x 2] is two sub-groups with no elements: the
            % inner index repeats and the outer index still counts them.
            numSamples = 4;
            row1 = zeros(numSamples, 0, 2);
            row2 = {ones(numSamples, 3)};

            [vector, index, indexIndex] = ...
                util.create_indexed_column({row1, row2}, 'Depth', 2);

            testCase.verifyEqual(size(vector.data), [numSamples, 3]);
            testCase.verifyEqual(index.data, uint64([0; 0; 3]));
            testCase.verifyEqual(indexIndex.data, uint64([2; 3]));
        end

        function testDepth2SingleSpikeRowAmongNDRows(testCase)
            % [num_samples x num_electrodes x num_spike_events] rows: a unit
            % with one spike event is [num_samples x num_electrodes], which is
            % one sub-group of num_electrodes elements, in either row order.
            numSamples = 4;
            numElectrodes = 3;
            oneSpike = reshape(1:(numSamples*numElectrodes), numSamples, numElectrodes);
            threeSpikes = 100 + reshape(1:(numSamples*numElectrodes*3), numSamples, numElectrodes, 3);

            [vector, index, indexIndex] = ...
                util.create_indexed_column({oneSpike, threeSpikes}, 'Depth', 2);

            testCase.verifyEqual(size(vector.data), [numSamples, 12]);
            testCase.verifyEqual(vector.data(:, 1:3), oneSpike);
            testCase.verifyEqual(index.data, uint64([3; 6; 9; 12]));
            testCase.verifyEqual(indexIndex.data, uint64([1; 4]));

            [vector, index, indexIndex] = ...
                util.create_indexed_column({threeSpikes, oneSpike}, 'Depth', 2);

            testCase.verifyEqual(vector.data(:, 10:12), oneSpike);
            testCase.verifyEqual(index.data, uint64([3; 6; 9; 12]));
            testCase.verifyEqual(indexIndex.data, uint64([3; 4]));
        end

        function testDepth2SingleSubGroupRowOfNDElements(testCase)
            % Elements [4 x 2]: a row with one sub-group of 5 elements is
            % [4 x 2 x 5], its trailing dimension of 1 omitted, in either order.
            threeSubGroups = reshape(1:(4*2*5*3), 4, 2, 5, 3);
            oneSubGroup = 1000 + reshape(1:(4*2*5), 4, 2, 5);

            [vector, index, indexIndex] = ...
                util.create_indexed_column({threeSubGroups, oneSubGroup}, 'Depth', 2);

            testCase.verifyEqual(size(vector.data), [4, 2, 20]);
            testCase.verifyEqual(vector.data(:, :, 16:20), oneSubGroup);
            testCase.verifyEqual(index.data, uint64([5; 10; 15; 20]));
            testCase.verifyEqual(indexIndex.data, uint64([3; 4]));

            [vector, index, indexIndex] = ...
                util.create_indexed_column({oneSubGroup, threeSubGroups}, 'Depth', 2);

            testCase.verifyEqual(vector.data(:, :, 1:5), oneSubGroup);
            testCase.verifyEqual(index.data, uint64([5; 10; 15; 20]));
            testCase.verifyEqual(indexIndex.data, uint64([1; 4]));
        end

        function testDepth2ShortcutKeptBesideCellRows(testCase)
            % A cell row does not switch the column to the full form: a
            % [k x m] row beside it still means m sub-groups of one element.
            numSamples = 4;
            unit1 = {ones(numSamples, 1), 2 * ones(numSamples, 1)};
            unit2 = 3 * ones(numSamples, 3);

            [vector, index, indexIndex] = ...
                util.create_indexed_column({unit1, unit2}, 'Depth', 2);

            testCase.verifyEqual(size(vector.data), [numSamples, 5]);
            testCase.verifyEqual(index.data, uint64((1:5)'));
            testCase.verifyEqual(indexIndex.data, uint64([2; 5]));
        end

        function testDepth3OmittedTrailingDimensions(testCase)
            % Elements [4], 2 per innermost group: [4 x 2 x 3] beside a
            % [4 x 2 x 3 x 4] row is 3 innermost groups in one middle group,
            % and [4 x 2] is one innermost group in one middle group.
            fullRow = reshape(1:(4*2*3*4), 4, 2, 3, 4);
            oneMiddleGroup = 1000 + reshape(1:(4*2*3), 4, 2, 3);
            oneInnermostGroup = 2000 + reshape(1:(4*2), 4, 2);

            [vector, index1, index2, index3] = util.create_indexed_column( ...
                {fullRow, oneMiddleGroup, oneInnermostGroup}, 'Depth', 3);

            testCase.verifyEqual(size(vector.data), [4, 32]);
            testCase.verifyEqual(vector.data(:, 25:30), reshape(oneMiddleGroup, 4, 6));
            testCase.verifyEqual(vector.data(:, 31:32), oneInnermostGroup);
            testCase.verifyEqual(index1.data, uint64((2:2:32)'));
            testCase.verifyEqual(index2.data, uint64([3; 6; 9; 12; 15; 16]));
            testCase.verifyEqual(index3.data, uint64([4; 5; 6]));
        end

        function testStringDescriptionIsStoredAsChar(testCase)
            vector = util.create_indexed_column({[1 2]}, "spike times");

            testCase.verifyClass(vector.description, 'char');
            testCase.verifyEqual(vector.description, 'spike times');
        end

        function testShapeErrorNamesTheRow(testCase)
            % Row 2 has 5-sample elements among 4-sample ones; the error names it.
            try
                util.create_indexed_column({ones(4, 2, 2), ones(5, 2)}, 'Depth', 2);
                testCase.verifyFail('Expected an error.');
            catch err
                testCase.verifyEqual(err.identifier, 'NWB:CreateIndexedColumn:InconsistentElementShape');
                testCase.verifySubstring(err.message, 'DATA{2}');
            end
        end

        function testDepth2Errors(testCase)
            testCase.verifyError( ...
                @() util.create_indexed_column({ones(3, 4), ones(2, 5)}, 'Depth', 2), ...
                'NWB:CreateIndexedColumn:InconsistentElementShape');
            testCase.verifyError( ...
                @() util.create_indexed_column({{ones(4, 2)}, "text"}, 'Depth', 2), ...
                'NWB:CreateIndexedColumn:InvalidRow');
            % A cell nested deeper than Depth is an error.
            testCase.verifyError( ...
                @() util.create_indexed_column({{[1 2 3]}}), ...
                'NWB:CreateIndexedColumn:InvalidRow');
        end

        function testTooManyOutputsErrors(testCase)
            testCase.verifyError(@() requestThreeOutputs({[1 2], 3}), ...
                'NWB:CreateIndexedColumn:TooManyOutputs');
        end

        function testMatrixRowsRoundTrip(testCase)
            % The ragged axis is last in MATLAB, so it is first on disk as the
            % schema requires, and the column survives export and read.
            row1 = reshape(1:8, 4, 2);
            row2 = 100 + reshape(1:12, 4, 3);
            [vector, index] = util.create_indexed_column({row1, row2}, 'waveform-like');

            dynamicTable = types.hdmf_common.DynamicTable('description', 'test');
            dynamicTable.addColumn('wf', vector, 'wf_index', index);
            testCase.verifyEqual(numel(dynamicTable.id.data), 2);

            nwb = NwbFile( ...
                'identifier', 'indexed_column_test', ...
                'session_description', 'test', ...
                'session_start_time', datetime(2024, 1, 1, 'TimeZone', 'local'));
            nwb.acquisition.set('DynamicTable', dynamicTable);

            fileName = testCase.getRandomFilename();
            nwbExport(nwb, fileName);

            testCase.verifyEqual(readOnDiskShape(fileName, '/acquisition/DynamicTable/wf'), [5, 4]);

            back = nwbRead(fileName, 'ignorecache');
            column = back.acquisition.get('DynamicTable').vectordata.get('wf');
            columnIndex = back.acquisition.get('DynamicTable').vectordata.get('wf_index');
            testCase.verifyEqual(column.data.load(), vector.data);
            testCase.verifyEqual(columnIndex.data.load(), uint64([2; 5]));
        end
    end
end

function shape = readOnDiskShape(fileName, datasetPath)
    % C-order shape of a dataset, i.e. the schema's dimension order. h5info
    % reports sizes in MATLAB order, so use the low-level API.
    fileId = H5F.open(fileName, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
    fileCleanup = onCleanup(@() H5F.close(fileId));
    datasetId = H5D.open(fileId, datasetPath);
    datasetCleanup = onCleanup(@() H5D.close(datasetId));
    spaceId = H5D.get_space(datasetId);
    spaceCleanup = onCleanup(@() H5S.close(spaceId));
    [~, shape] = H5S.get_simple_extent_dims(spaceId);
    delete(spaceCleanup)
    delete(datasetCleanup)
    delete(fileCleanup)
end

function spikeEvents = splitSpikeEvents(unitWaveforms)
    % Split [num_samples x num_electrodes x num_spike_events] into one
    % [num_samples x num_electrodes] matrix per spike event, independently of
    % the code under test.
    numSpikeEvents = size(unitWaveforms, 3);
    spikeEvents = cell(1, numSpikeEvents);
    for iSpikeEvent = 1:numSpikeEvents
        spikeEvents{iSpikeEvent} = unitWaveforms(:, :, iSpikeEvent);
    end
end

function requestThreeOutputs(data)
    [~, ~, ~] = util.create_indexed_column(data);
end
