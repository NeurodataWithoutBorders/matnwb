classdef dynamicTableRaggedArrayTest < tests.abstract.NwbTestCase
% dynamicTableRaggedArrayTest - Tests for the DynamicTable addRaggedArray and
% addDoublyRaggedArray convenience methods.

    methods (TestClassSetup)
        function setupClass(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testAddRaggedArray(testCase)
            dt = types.hdmf_common.DynamicTable('description', 'test');
            dt.addRaggedArray('spikes', {[1 2 3], [4 5]}, 'description', 'spike times');

            testCase.verifyTrue(any(strcmp(dt.colnames, 'spikes')));
            testCase.verifyEqual(numel(dt.id.data), 2);
            % Cumulative row boundaries for a 3- and 2-element row.
            testCase.verifyEqual(dt.vectordata.get('spikes_index').data, uint64([3; 5]));
            testCase.verifyEqual(dt.vectordata.get('spikes').description, 'spike times');
        end

        function testAddRaggedArrayWithTableRegion(testCase)
            target = types.hdmf_common.DynamicTable( ...
                'description', 'target', ...
                'colnames', {'x'}, ...
                'x', types.hdmf_common.VectorData('description', 'x', 'data', (1:5)'), ...
                'id', types.hdmf_common.ElementIdentifiers('data', (0:4)'));

            dt = types.hdmf_common.DynamicTable('description', 'test');
            dt.addRaggedArray('regions', {[0 1], [2 3 4]}, ...
                'description', 'regions', 'table', target);

            column = dt.vectordata.get('regions');
            testCase.verifyClass(column, 'types.hdmf_common.DynamicTableRegion');
            testCase.verifyEqual(dt.vectordata.get('regions_index').data, uint64([2; 5]));
        end

        function testAddDoublyRaggedArrayGeneric(testCase)
            nSamples = 4;
            unit1 = reshape(1:(3*nSamples), 3, nSamples);
            unit2 = 100 + reshape(1:(4*nSamples), 4, nSamples);

            dt = types.hdmf_common.DynamicTable('description', 'test');
            dt.addDoublyRaggedArray('wf', {unit1, unit2}, 'description', 'waveforms');

            testCase.verifyEqual(dt.colnames, {'wf'});
            testCase.verifyEqual(numel(dt.id.data), 2);
            testCase.verifyEqual(size(dt.vectordata.get('wf').data), [nSamples, 7]);
            testCase.verifyEqual(dt.vectordata.get('wf_index').data, uint64((1:7)'));
            testCase.verifyEqual(dt.vectordata.get('wf_index_index').data, uint64([3; 7]));
        end

        function testAddDoublyRaggedArrayWithNDArrayElements(testCase)
            unit1 = {reshape(1:(2*3*4), 2, 3, 4), ...
                100 + reshape(1:(1*3*4), 1, 3, 4)};
            unit2 = {200 + reshape(1:(3*3*4), 3, 3, 4)};

            dt = types.hdmf_common.DynamicTable('description', 'test');
            dt.addDoublyRaggedArray('wf', {unit1, unit2}, 'description', 'volumes');

            testCase.verifyEqual(size(dt.vectordata.get('wf').data), [4, 3, 6]);
            testCase.verifyEqual(dt.vectordata.get('wf').data(:, :, 1), ...
                reshape(unit1{1}(1, :, :), 3, 4).');
            testCase.verifyEqual(dt.vectordata.get('wf').data(:, :, 6), ...
                reshape(unit2{1}(3, :, :), 3, 4).');
            testCase.verifyEqual(dt.vectordata.get('wf_index').data, uint64([2; 3; 6]));
            testCase.verifyEqual(dt.vectordata.get('wf_index_index').data, uint64([2; 3]));
        end

        function testAddDoublyRaggedArrayOnUnitsRoundTrip(testCase)
            nSamples = 4;
            unit1 = reshape(1:(3*nSamples), 3, nSamples);
            unit2 = 100 + reshape(1:(4*nSamples), 4, nSamples);

            units = types.core.Units('colnames', {}, 'description', 'units');
            units.addDoublyRaggedArray('waveforms', {unit1, unit2}, ...
                'description', 'spike waveforms');

            testCase.verifyTrue(any(strcmp(units.colnames, 'waveforms')));

            nwb = NwbFile( ...
                'identifier', 'ragged_method_test', ...
                'session_description', 'test', ...
                'session_start_time', datetime(2024, 1, 1, 'TimeZone', 'local'));
            nwb.units = units;

            fileName = testCase.getRandomFilename();
            nwbExport(nwb, fileName);

            back = nwbRead(fileName, 'ignorecache');
            testCase.verifyEqual(back.units.waveforms_index.data.load(), uint64((1:7)'));
            testCase.verifyEqual(back.units.waveforms_index_index.data.load(), uint64([3; 7]));
        end

        function testUnitsWaveforms3DArrayMatchesPynwbLayout(testCase)
            % PyNWB's Units.add_unit reads 3-D waveforms as
            % [nSpikes x nElectrodes x nSamples]. For these two units it
            % stores data (20, 2), waveforms_index [4 8 12 16 20] and
            % waveforms_index_index [3 5].
            numElectrodes = 4;
            numSamples = 2;
            unit1 = reshape(1:(3*numElectrodes*numSamples), 3, numElectrodes, numSamples);
            unit2 = 100 + reshape(1:(2*numElectrodes*numSamples), 2, numElectrodes, numSamples);

            units = types.core.Units('colnames', {}, 'description', 'units');
            units.addDoublyRaggedArray('waveforms', {unit1, unit2});

            waveforms = units.waveforms.data;
            testCase.verifyEqual(size(waveforms), [numSamples, 20]);
            % Row k of the stored dataset is one electrode's waveform for one spike.
            testCase.verifyEqual(waveforms(:, 1), reshape(unit1(1, 1, :), [], 1));
            testCase.verifyEqual(waveforms(:, 7), reshape(unit1(2, 3, :), [], 1));
            testCase.verifyEqual(waveforms(:, 20), reshape(unit2(2, 4, :), [], 1));
            testCase.verifyEqual(units.waveforms_index.data, uint64([4; 8; 12; 16; 20]));
            testCase.verifyEqual(units.waveforms_index_index.data, uint64([3; 5]));
        end

        function testUnitsWaveforms3DArrayEqualsCellForm(testCase)
            unit1 = rand(3, 4, 2);
            unit2 = rand(2, 4, 2);
            cellForm = {toSpikeCells(unit1), toSpikeCells(unit2)};

            fromArray = types.core.Units('colnames', {}, 'description', 'units');
            fromArray.addDoublyRaggedArray('waveforms', {unit1, unit2});
            fromCell = types.core.Units('colnames', {}, 'description', 'units');
            fromCell.addDoublyRaggedArray('waveforms', cellForm);

            testCase.verifyEqual(fromArray.waveforms.data, fromCell.waveforms.data);
            testCase.verifyEqual(fromArray.waveforms_index.data, fromCell.waveforms_index.data);
            testCase.verifyEqual(fromArray.waveforms_index_index.data, ...
                fromCell.waveforms_index_index.data);
        end

        function testUnitsWaveforms3DArrayRoundTrip(testCase)
            unit1 = rand(3, 4, 2);
            unit2 = rand(2, 4, 2);

            nwb = NwbFile( ...
                'identifier', 'units_waveforms_3d', ...
                'session_description', 'test', ...
                'session_start_time', datetime(2024, 1, 1, 'TimeZone', 'local'));
            nwb.units = types.core.Units('colnames', {}, 'description', 'units');
            nwb.units.addDoublyRaggedArray('waveforms', {unit1, unit2});

            fileName = testCase.getRandomFilename();
            nwbExport(nwb, fileName);

            back = nwbRead(fileName, 'ignorecache');
            testCase.verifyEqual(size(back.units.waveforms.data.load()), [2, 20]);
            testCase.verifyEqual(back.units.waveforms_index.data.load(), uint64([4; 8; 12; 16; 20]));
            testCase.verifyEqual(back.units.waveforms_index_index.data.load(), uint64([3; 5]));
        end

        function testAddDoublyRaggedArrayExistingColumnErrors(testCase)
            % Like addColumn, adding a column that already exists is an error,
            % both for generic columns and for schema-defined properties.
            unit1 = reshape(1:8, 2, 4);
            unit2 = reshape(1:12, 3, 4);

            dt = types.hdmf_common.DynamicTable('description', 'test');
            dt.addDoublyRaggedArray('wf', {unit1, unit2});
            testCase.verifyError( ...
                @() dt.addDoublyRaggedArray('wf', {unit1, unit2}), ...
                'NWB:DynamicTable:AddDoublyRaggedArray:ColumnExists');

            units = types.core.Units('colnames', {}, 'description', 'units');
            units.addDoublyRaggedArray('waveforms', {unit1, unit2});
            testCase.verifyError( ...
                @() units.addDoublyRaggedArray('waveforms', {unit1, unit2}), ...
                'NWB:DynamicTable:AddDoublyRaggedArray:ColumnExists');
        end

        function testAddDoublyRaggedArrayHeightMismatchErrors(testCase)
            dt = types.hdmf_common.DynamicTable('description', 'test');
            dt.addColumn('a', types.hdmf_common.VectorData( ...
                'description', 'a', 'data', [1 2 3]'));  % 3 rows

            testCase.verifyError( ...
                @() dt.addDoublyRaggedArray('wf', {reshape(1:8, 2, 4), reshape(1:8, 2, 4)}), ...
                'NWB:DynamicTable:AddDoublyRaggedArray:MissingRows');
        end
    end
end

function spikeCells = toSpikeCells(unitWaveforms)
    % Split [nSpikes x nElectrodes x nSamples] into one [nElectrodes x nSamples]
    % matrix per spike, independently of the code under test.
    [numSpikes, numElectrodes, numSamples] = size(unitWaveforms);
    spikeCells = cell(1, numSpikes);
    for iSpike = 1:numSpikes
        spikeCells{iSpike} = squeeze(unitWaveforms(iSpike, :, :));
        assert(isequal(size(spikeCells{iSpike}), [numElectrodes, numSamples]))
    end
end
