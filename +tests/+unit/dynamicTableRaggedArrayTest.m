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
