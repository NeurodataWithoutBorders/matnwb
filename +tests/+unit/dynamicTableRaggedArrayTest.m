classdef dynamicTableRaggedArrayTest < tests.abstract.NwbTestCase
% dynamicTableRaggedArrayTest - Tests for the DynamicTable addRaggedArray and
% addDoublyRaggedArray convenience methods.

    methods (TestClassSetup)
        function setupClass(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testAddRaggedArrayPixelMaskOnPlaneSegmentation(testCase)
            % Pixel masks as one table of all pixels plus the pixel count of
            % each ROI; PlaneSegmentation stores them on its typed properties.
            pixels = table(uint32([1; 2; 3; 7; 8]), uint32([4; 4; 4; 9; 9]), single(ones(5, 1)), ...
                'VariableNames', {'x', 'y', 'weight'});

            planeSegmentation = types.core.PlaneSegmentation('description', 'rois', 'colnames', {});
            planeSegmentation.addRaggedArray('pixel_mask', pixels, 'ElementsPerRow', [3 2], ...
                'description', 'pixel masks');

            testCase.verifyEqual(planeSegmentation.colnames, {'pixel_mask'});
            testCase.verifyEqual(planeSegmentation.pixel_mask.data, pixels);
            testCase.verifyEqual(planeSegmentation.pixel_mask_index.data, uint64([3; 5]));
            testCase.verifyEqual(planeSegmentation.id.data, int64([0; 1]));
        end

        function testAddRaggedArrayCompoundRoundTrip(testCase)
            roi1 = table(uint32([1; 2; 3]), uint32([4; 4; 4]), single([1; 1; 1]), ...
                'VariableNames', {'x', 'y', 'weight'});
            roi2 = table(uint32([7; 8]), uint32([9; 9]), single([0.5; 0.5]), ...
                'VariableNames', {'x', 'y', 'weight'});
            dt = types.hdmf_common.DynamicTable('description', 'test');
            dt.addRaggedArray('mask', {roi1, roi2}, 'description', 'masks');

            nwb = NwbFile( ...
                'identifier', 'ragged_compound_test', ...
                'session_description', 'test', ...
                'session_start_time', datetime(2024, 1, 1, 'TimeZone', 'local'));
            nwb.acquisition.set('DynamicTable', dt);
            fileName = testCase.getRandomFilename();
            nwbExport(nwb, fileName);

            back = nwbRead(fileName, 'ignorecache');
            tableBack = back.acquisition.get('DynamicTable');
            % Compound data is read back as a scalar struct of columns.
            testCase.verifyEqual(struct2table(tableBack.vectordata.get('mask').data.load()), [roi1; roi2]);
            testCase.verifyEqual(tableBack.vectordata.get('mask_index').data.load(), uint64([3; 5]));
        end

        function testAddRaggedArrayWithTextRowsRoundTrip(testCase)
            dt = types.hdmf_common.DynamicTable('description', 'test');
            dt.addRaggedArray('tags', {{'1a'; '1b'; '1c'}, {'2a'}}, 'description', 'tags');

            nwb = NwbFile( ...
                'identifier', 'ragged_text_test', ...
                'session_description', 'test', ...
                'session_start_time', datetime(2024, 1, 1, 'TimeZone', 'local'));
            nwb.acquisition.set('DynamicTable', dt);
            fileName = testCase.getRandomFilename();
            nwbExport(nwb, fileName);

            back = nwbRead(fileName, 'ignorecache');
            table = back.acquisition.get('DynamicTable');
            testCase.verifyEqual(table.vectordata.get('tags').data.load(), {'1a'; '1b'; '1c'; '2a'});
            testCase.verifyEqual(table.vectordata.get('tags_index').data.load(), uint64([3; 4]));
        end

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
                'description', 'raw data of each trial');

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
            % Tables such as those in the icephys hierarchy get their ids in
            % the constructor and their ragged column afterwards.
            dt = types.hdmf_common.DynamicTable('description', 'test', ...
                'id', types.hdmf_common.ElementIdentifiers('data', int64([19; 21])));
            dt.addRaggedArray('refs', {0, [0 1]});

            testCase.verifyEqual(dt.vectordata.get('refs_index').data, uint64([1; 3]));
            testCase.verifyError(@() dt.addRaggedArray('more', {0}), ...
                'NWB:DynamicTable:AddColumn:MissingRows');
        end

        function testAddRaggedArray(testCase)
            dt = types.hdmf_common.DynamicTable('description', 'test');
            dt.addRaggedArray('spikes', {[1 2 3], [4 5]}, 'description', 'spike times');

            testCase.verifyTrue(any(strcmp(dt.colnames, 'spikes')));
            testCase.verifyEqual(numel(dt.id.data), 2);
            % Cumulative row boundaries for a 3- and 2-element row.
            testCase.verifyEqual(dt.vectordata.get('spikes_index').data, uint64([3; 5]));
            testCase.verifyEqual(dt.vectordata.get('spikes').description, 'spike times');
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
                'description', 'regions', 'table', target);

            column = dt.vectordata.get('regions');
            testCase.verifyClass(column, 'types.hdmf_common.DynamicTableRegion');
            testCase.verifyEqual(dt.vectordata.get('regions_index').data, uint64([2; 5]));
        end

        function testAddRaggedArrayDepth2Generic(testCase)
            % [num_samples x num_waveforms] per row: one waveform per sub-group.
            numSamples = 4;
            unit1 = reshape(1:(3*numSamples), numSamples, 3);
            unit2 = 100 + reshape(1:(4*numSamples), numSamples, 4);

            dt = types.hdmf_common.DynamicTable('description', 'test');
            dt.addRaggedArray('wf', {unit1, unit2}, 'description', 'waveforms', 'Depth', 2);

            testCase.verifyEqual(dt.colnames, {'wf'});
            testCase.verifyEqual(numel(dt.id.data), 2);
            testCase.verifyEqual(dt.vectordata.get('wf').data, [unit1, unit2]);
            testCase.verifyEqual(dt.vectordata.get('wf_index').data, uint64((1:7)'));
            testCase.verifyEqual(dt.vectordata.get('wf_index_index').data, uint64([3; 7]));
        end

        function testAddDoublyRaggedArrayIsDepth2(testCase)
            numSamples = 4;
            unit1 = reshape(1:(3*numSamples), numSamples, 3);
            unit2 = 100 + reshape(1:(4*numSamples), numSamples, 4);

            viaDepth = types.hdmf_common.DynamicTable('description', 'test');
            viaDepth.addRaggedArray('wf', {unit1, unit2}, 'description', 'waveforms', 'Depth', 2);
            viaAlias = types.hdmf_common.DynamicTable('description', 'test');
            viaAlias.addDoublyRaggedArray('wf', {unit1, unit2}, 'description', 'waveforms');

            for name = ["wf", "wf_index", "wf_index_index"]
                testCase.verifyEqual(viaAlias.vectordata.get(name).data, ...
                    viaDepth.vectordata.get(name).data);
            end
        end

        function testAddRaggedArrayDepth2WithNDElements(testCase)
            % data{row}{subGroup} = [elementDims x nElements]; here elements are
            % [4 x 3] and the ragged axis stays last.
            unit1 = {reshape(1:(4*3*2), 4, 3, 2), 100 + reshape(1:(4*3), 4, 3)};
            unit2 = {200 + reshape(1:(4*3*3), 4, 3, 3)};

            dt = types.hdmf_common.DynamicTable('description', 'test');
            dt.addRaggedArray('wf', {unit1, unit2}, 'description', 'volumes', 'Depth', 2);

            testCase.verifyEqual(size(dt.vectordata.get('wf').data), [4, 3, 6]);
            testCase.verifyEqual(dt.vectordata.get('wf').data(:, :, 1), unit1{1}(:, :, 1));
            testCase.verifyEqual(dt.vectordata.get('wf').data(:, :, 6), unit2{1}(:, :, 3));
            testCase.verifyEqual(dt.vectordata.get('wf_index').data, uint64([2; 3; 6]));
            testCase.verifyEqual(dt.vectordata.get('wf_index_index').data, uint64([2; 3]));
        end

        function testUnitsWaveformsRoundTrip(testCase)
            numSamples = 4;
            unit1 = reshape(1:(3*numSamples), numSamples, 3);
            unit2 = 100 + reshape(1:(4*numSamples), numSamples, 4);

            units = types.core.Units('colnames', {}, 'description', 'units');
            units.addRaggedArray('waveforms', {unit1, unit2}, ...
                'description', 'spike waveforms', 'Depth', 2);

            testCase.verifyTrue(any(strcmp(units.colnames, 'waveforms')));
            % Schema-defined columns are stored on the typed properties.
            testCase.verifyClass(units.waveforms_index_index, 'types.hdmf_common.VectorIndex');

            nwb = NwbFile( ...
                'identifier', 'ragged_method_test', ...
                'session_description', 'test', ...
                'session_start_time', datetime(2024, 1, 1, 'TimeZone', 'local'));
            nwb.units = units;

            fileName = testCase.getRandomFilename();
            nwbExport(nwb, fileName);

            back = nwbRead(fileName, 'ignorecache');
            testCase.verifyEqual(back.units.waveforms.data.load(), [unit1, unit2]);
            testCase.verifyEqual(back.units.waveforms_index.data.load(), uint64((1:7)'));
            testCase.verifyEqual(back.units.waveforms_index_index.data.load(), uint64([3; 7]));
        end

        function testUnitsWaveforms3DArrayMatchesPynwbLayout(testCase)
            % PyNWB's Units.add_unit takes (num_spikes, num_electrodes,
            % num_samples) per unit; with the dimensions reversed that is
            % [num_samples x num_electrodes x num_spike_events] here. For these
            % two units PyNWB stores data (20, 2), waveforms_index
            % [4 8 12 16 20] and waveforms_index_index [3 5] (hdmf 6.2.0).
            numElectrodes = 4;
            numSamples = 2;
            unit1 = reshape(1:(numSamples*numElectrodes*3), numSamples, numElectrodes, 3);
            unit2 = 100 + reshape(1:(numSamples*numElectrodes*2), numSamples, numElectrodes, 2);

            units = types.core.Units('colnames', {}, 'description', 'units');
            units.addRaggedArray('waveforms', {unit1, unit2}, 'Depth', 2);

            waveforms = units.waveforms.data;
            testCase.verifyEqual(size(waveforms), [numSamples, 20]);
            % Column k is one electrode's waveform for one spike event.
            testCase.verifyEqual(waveforms(:, 1), unit1(:, 1, 1));
            testCase.verifyEqual(waveforms(:, 7), unit1(:, 3, 2));
            testCase.verifyEqual(waveforms(:, 20), unit2(:, 4, 2));
            testCase.verifyEqual(units.waveforms_index.data, uint64([4; 8; 12; 16; 20]));
            testCase.verifyEqual(units.waveforms_index_index.data, uint64([3; 5]));
        end

        function testUnitsWaveforms3DArrayEqualsCellForm(testCase)
            unit1 = rand(2, 4, 3);
            unit2 = rand(2, 4, 2);
            cellForm = {splitSpikeEvents(unit1), splitSpikeEvents(unit2)};

            fromArray = types.core.Units('colnames', {}, 'description', 'units');
            fromArray.addRaggedArray('waveforms', {unit1, unit2}, 'Depth', 2);
            fromCell = types.core.Units('colnames', {}, 'description', 'units');
            fromCell.addRaggedArray('waveforms', cellForm, 'Depth', 2);

            testCase.verifyEqual(fromArray.waveforms.data, fromCell.waveforms.data);
            testCase.verifyEqual(fromArray.waveforms_index.data, fromCell.waveforms_index.data);
            testCase.verifyEqual(fromArray.waveforms_index_index.data, ...
                fromCell.waveforms_index_index.data);
        end

        function testUnitsWaveforms3DArrayRoundTrip(testCase)
            unit1 = rand(2, 4, 3);
            unit2 = rand(2, 4, 2);

            nwb = NwbFile( ...
                'identifier', 'units_waveforms_3d', ...
                'session_description', 'test', ...
                'session_start_time', datetime(2024, 1, 1, 'TimeZone', 'local'));
            nwb.units = types.core.Units('colnames', {}, 'description', 'units');
            nwb.units.addRaggedArray('waveforms', {unit1, unit2}, 'Depth', 2);

            fileName = testCase.getRandomFilename();
            nwbExport(nwb, fileName);

            back = nwbRead(fileName, 'ignorecache');
            testCase.verifyEqual(size(back.units.waveforms.data.load()), [2, 20]);
            testCase.verifyEqual(back.units.waveforms_index.data.load(), uint64([4; 8; 12; 16; 20]));
            testCase.verifyEqual(back.units.waveforms_index_index.data.load(), uint64([3; 5]));
        end

        function testAddRaggedArrayExistingColumnErrors(testCase)
            % Adding a column that already exists is an error at any depth,
            % both for generic columns and for schema-defined properties.
            unit1 = reshape(1:8, 4, 2);
            unit2 = reshape(1:12, 4, 3);

            dt = types.hdmf_common.DynamicTable('description', 'test');
            dt.addRaggedArray('wf', {unit1, unit2}, 'Depth', 2);
            testCase.verifyError( ...
                @() dt.addRaggedArray('wf', {unit1, unit2}, 'Depth', 2), ...
                'NWB:DynamicTable:AddColumn:ColumnExists');

            units = types.core.Units('colnames', {}, 'description', 'units');
            units.addRaggedArray('waveforms', {unit1, unit2}, 'Depth', 2);
            testCase.verifyError( ...
                @() units.addRaggedArray('waveforms', {unit1, unit2}, 'Depth', 2), ...
                'NWB:DynamicTable:AddColumn:ColumnExists');
        end

        function testAddRaggedArrayHeightMismatchErrors(testCase)
            dt = types.hdmf_common.DynamicTable('description', 'test');
            dt.addColumn('a', types.hdmf_common.VectorData( ...
                'description', 'a', 'data', [1 2 3]'));  % 3 rows

            % The outermost index has 2 entries, one per row given.
            testCase.verifyError( ...
                @() dt.addRaggedArray('wf', {reshape(1:8, 4, 2), reshape(1:8, 4, 2)}, 'Depth', 2), ...
                'NWB:DynamicTable:AddColumn:MissingRows');
        end
    end
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
