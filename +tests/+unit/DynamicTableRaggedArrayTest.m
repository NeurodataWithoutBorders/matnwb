classdef DynamicTableRaggedArrayTest < tests.abstract.NwbTestCase
% DynamicTableRaggedArrayTest - Tests for the DynamicTable addRaggedArray and
% addDoublyRaggedArray convenience methods.

    methods (TestClassSetup)
        function setupClass(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testAddRaggedArrayWithObjectViewRowsRoundTrip(testCase)
            % Each trial references the TimeSeries recorded during it, with
            % [] for a trial that has none.
            raw1 = types.core.TimeSeries('description', 'raw 1', 'data', [1 2 3], ...
                'data_unit', 'V', 'starting_time', 0, 'starting_time_rate', 1);
            raw3 = types.core.TimeSeries('description', 'raw 3', 'data', [4 5 6], ...
                'data_unit', 'V', 'starting_time', 0, 'starting_time_rate', 1);
            trials = types.core.TimeIntervals('description', 'trials', ...
                'colnames', {'start_time', 'stop_time'});
            trials.addRow('start_time', 0, 'stop_time', 1);
            trials.addRow('start_time', 2, 'stop_time', 3);
            trials.addRow('start_time', 4, 'stop_time', 5);
            trials.addRaggedArray('raw_data', ...
                {types.untyped.ObjectView(raw1), [], types.untyped.ObjectView(raw3)}, ...
                'Description', 'raw data of each trial');

            nwb = NwbFile( ...
                'identifier', 'ragged_object_test', ...
                'session_description', 'test', ...
                'session_start_time', datetime(2024, 1, 1, 'TimeZone', 'local'));
            nwb.acquisition.set('raw1', raw1);
            nwb.acquisition.set('raw3', raw3);
            nwb.intervals_trials = trials;
            fileName = testCase.getRandomFilename();
            nwbExport(nwb, fileName);

            back = nwbRead(fileName, 'ignorecache');
            references = back.intervals_trials.vectordata.get('raw_data').data;
            testCase.verifyClass(references, 'types.untyped.ObjectView');
            testCase.verifyEqual({references.path}, {'/acquisition/raw1', '/acquisition/raw3'});
            testCase.verifyEqual( ...
                back.intervals_trials.vectordata.get('raw_data_index').data.load(), ...
                uint64([1; 1; 2]));
        end

        function testAddRaggedArrayToTableWithIdsOnly(testCase)
            % A table can be constructed with its ids only and get a ragged
            % column afterwards. The ids then set the number of rows.
            dt = types.hdmf_common.DynamicTable('description', 'test', ...
                'id', types.hdmf_common.ElementIdentifiers('data', int64([19; 21])));
            dt.addRaggedArray('refs', {0, [0 1]});

            testCase.verifyEqual(dt.vectordata.get('refs_index').data, uint64([1; 3]));
            testCase.verifyError(@() dt.addRaggedArray('more', {0}), ...
                'NWB:DynamicTable:AddColumn:MissingRows');
        end

        function testAddRaggedArray(testCase)
            dt = types.hdmf_common.DynamicTable('description', 'test');
            dt.addRaggedArray('spikes', {[1 2 3], [4 5]}, 'Description', 'spike times');

            testCase.verifyTrue(any(strcmp(dt.colnames, 'spikes')));
            testCase.verifyEqual(numel(dt.id.data), 2);
            % Cumulative row boundaries for a 3- and 2-element row.
            testCase.verifyEqual(dt.vectordata.get('spikes_index').data, uint64([3; 5]));
            testCase.verifyEqual(dt.vectordata.get('spikes').description, 'spike times');
        end

        function testDescriptionThatStartsAnOptionNameIsStored(testCase)
            % 'depth' and 'Dep' start the option name 'Depth' of
            % util.create_indexed_column, and 'ElementsPerRow' is one of its
            % option names.
            for description = ["depth", "Dep", "ElementsPerRow"]
                dt = types.hdmf_common.DynamicTable('description', 'test');
                dt.addRaggedArray('x', {[1 2], 3}, 'Description', description);

                testCase.verifyEqual(dt.vectordata.get('x').description, char(description));
            end

            dt = types.hdmf_common.DynamicTable('description', 'test');
            dt.addDoublyRaggedArray('x', {{[1 2], 3}, {4}}, 'Description', 'depth');
            testCase.verifyEqual(dt.vectordata.get('x').description, 'depth');
        end

        function testAddRaggedArrayWithoutDescription(testCase)
            dt = types.hdmf_common.DynamicTable('description', 'test');
            dt.addRaggedArray('x', {[1 2], 3});

            testCase.verifyEqual(dt.vectordata.get('x').description, 'no description');
        end

        function testAddRaggedArrayWithMatrixRows(testCase)
            % Elements are 4-sample vectors, one per column, as in VectorData.data.
            row1 = reshape(1:8, 4, 2);
            row2 = 100 + reshape(1:12, 4, 3);

            dt = types.hdmf_common.DynamicTable('description', 'test');
            dt.addRaggedArray('wf', {row1, row2});

            testCase.verifyEqual(numel(dt.id.data), 2);
            testCase.verifyEqual(dt.vectordata.get('wf').data, [row1, row2]);
            testCase.verifyEqual(dt.vectordata.get('wf_index').data, uint64([2; 5]));
        end

        function testAddRaggedArrayWithTableRegion(testCase)
            target = types.hdmf_common.DynamicTable( ...
                'description', 'target', ...
                'colnames', {'x'}, ...
                'x', types.hdmf_common.VectorData('description', 'x', 'data', (1:5)'), ...
                'id', types.hdmf_common.ElementIdentifiers('data', (0:4)'));

            dt = types.hdmf_common.DynamicTable('description', 'test');
            dt.addRaggedArray('regions', {[0 1], [2 3 4]}, ...
                'Description', 'regions', 'TargetTable', target);

            column = dt.vectordata.get('regions');
            testCase.verifyClass(column, 'types.hdmf_common.DynamicTableRegion');
            testCase.verifyEqual(dt.vectordata.get('regions_index').data, uint64([2; 5]));

            % A description that is an option name of
            % util.create_indexed_column is stored beside a table too.
            dt = types.hdmf_common.DynamicTable('description', 'test');
            dt.addRaggedArray('regions', {[0 1], [2 3 4]}, ...
                'Description', 'depth', 'TargetTable', target);
            column = dt.vectordata.get('regions');
            testCase.verifyClass(column, 'types.hdmf_common.DynamicTableRegion');
            testCase.verifyEqual(column.description, 'depth');
        end

        function testAddRaggedArrayTableMustBeADynamicTable(testCase)
            dt = types.hdmf_common.DynamicTable('description', 'test');

            testCase.verifyError( ...
                @() dt.addRaggedArray('regions', {[0 1], 2}, 'TargetTable', 5), ...
                'NWB:validators:mustBeDynamicTable');
        end

        function testAddDoublyRaggedArrayIsDepth2(testCase)
            numSamples = 4;
            unit1 = {reshape(1:(2*numSamples), numSamples, 2), 50+(1:numSamples)'};
            unit2 = {100+reshape(1:(3*numSamples), numSamples, 3)};

            viaDepth = types.hdmf_common.DynamicTable('description', 'test');
            viaDepth.addRaggedArray('wf', {unit1, unit2}, 'Description', 'waveforms', 'Depth', 2);
            viaAlias = types.hdmf_common.DynamicTable('description', 'test');
            viaAlias.addDoublyRaggedArray('wf', {unit1, unit2}, 'Description', 'waveforms');

            for name = ["wf", "wf_index", "wf_index_index"]
                testCase.verifyEqual(viaAlias.vectordata.get(name).data, ...
                    viaDepth.vectordata.get(name).data);
            end
            testCase.verifyEqual(viaDepth.colnames, {'wf'});
            testCase.verifyEqual(viaDepth.vectordata.get('wf_index').data, uint64([2; 3; 6]));
            testCase.verifyEqual(viaDepth.vectordata.get('wf_index_index').data, uint64([2; 3]));
        end

        function testAddRaggedArrayDepth2WithNDElements(testCase)
            % data{row}{subGroup} = [elementDims x nElements]; here elements are
            % [4 x 3] and the ragged axis stays last.
            unit1 = {reshape(1:(4*3*2), 4, 3, 2), 100+reshape(1:(4*3), 4, 3)};
            unit2 = {200+reshape(1:(4*3*3), 4, 3, 3)};

            dt = types.hdmf_common.DynamicTable('description', 'test');
            dt.addRaggedArray('wf', {unit1, unit2}, 'Description', 'volumes', 'Depth', 2);

            testCase.verifyEqual(size(dt.vectordata.get('wf').data), [4, 3, 6]);
            testCase.verifyEqual(dt.vectordata.get('wf').data(:, :, 1), unit1{1}(:, :, 1));
            testCase.verifyEqual(dt.vectordata.get('wf').data(:, :, 6), unit2{1}(:, :, 3));
            testCase.verifyEqual(dt.vectordata.get('wf_index').data, uint64([2; 3; 6]));
            testCase.verifyEqual(dt.vectordata.get('wf_index_index').data, uint64([2; 3]));
        end
    end
end
