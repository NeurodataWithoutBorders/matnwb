function ragged_arrays_examples()
% ragged_arrays_examples - Runnable snippets for the "Storing Ragged and
% Doubly-Ragged Array Columns" how-to guide.
%
% Each region between "% snippet: <name>" and "% end snippet" markers is
% embedded into docs/source/pages/how_to/ragged_arrays.rst via literalinclude.
% The snippets appear here in the order of the guide, and together they
% define every variable they use, so a reader can run the guide from top to
% bottom. The assertions between the snippets keep the guide's code correct.
% tests/unit/howToRaggedArrayExamplesTest runs this function, and runs the
% snippets on their own.

    numSamples = 40;   % for the assertions; the snippets state it as 40

    % snippet: ragged-spike-times
    units = types.core.Units('colnames', {}, 'description', 'units');
    units.addRaggedArray('spike_times', {[0.1 0.2 0.3], [0.5 0.6]}, ...
        'description', 'spike times');
    % end snippet
    assert(isequal(units.spike_times_index.data(:).', uint64([3 5])))

    % snippet: electrodes-table
    device = types.core.Device();
    electrodeGroup = types.core.ElectrodeGroup( ...
        'description', 'example group', 'location', 'cortex', ...
        'device', types.untyped.SoftLink(device));
    groupReference = types.untyped.ObjectView(electrodeGroup);
    electrodesTable = types.core.ElectrodesTable( ...
        'colnames', {'location', 'group', 'group_name'}, ...
        'description', 'electrodes', ...
        'location', types.hdmf_common.VectorData('description', 'location', ...
            'data', {'cortex'; 'cortex'; 'cortex'}), ...
        'group', types.hdmf_common.VectorData('description', 'group', ...
            'data', [groupReference; groupReference; groupReference]), ...
        'group_name', types.hdmf_common.VectorData('description', 'group name', ...
            'data', {'g'; 'g'; 'g'}), ...
        'id', types.hdmf_common.ElementIdentifiers('data', (0:2)'));
    % end snippet

    % snippet: ragged-electrodes-region
    units.addRaggedArray('electrodes', {[0 1 2], [0 1 2]}, 'table', electrodesTable);
    % end snippet
    assert(isa(units.electrodes, 'types.hdmf_common.DynamicTableRegion'))

    % snippet: text-column
    trials = types.core.TimeIntervals('description', 'trials', ...
        'colnames', {'start_time', 'stop_time'});
    trials.addRow('start_time', 0.0, 'stop_time', 1.0);
    trials.addRow('start_time', 2.0, 'stop_time', 3.0);
    trials.addRaggedArray('tags', {["go", "rewarded"], "nogo"}, ...
        'description', 'trial tags');
    % end snippet
    assert(isequal(trials.tags.data, ["go"; "rewarded"; "nogo"]))
    assert(isequal(trials.tags_index.data(:).', uint64([2 3])))

    % snippet: compound-pixel-masks
    roi1 = table(uint32([1; 2; 3]), uint32([4; 4; 4]), single([1; 1; 1]), ...
        'VariableNames', {'x', 'y', 'weight'});
    roi2 = table(uint32([7; 8]), uint32([9; 9]), single([1; 1]), ...
        'VariableNames', {'x', 'y', 'weight'});
    planeSegmentation = types.core.PlaneSegmentation('description', 'rois');
    planeSegmentation.addRaggedArray('pixel_mask', {roi1, roi2}, ...
        'description', 'pixel masks');
    % end snippet
    assert(isequal(planeSegmentation.pixel_mask.data, [roi1; roi2]))
    assert(isequal(planeSegmentation.pixel_mask_index.data(:).', uint64([3 5])))

    % snippet: object-reference-rows
    rawTrial1 = types.core.TimeSeries('description', 'raw data of trial 1');
    rawTrial3 = types.core.TimeSeries('description', 'raw data of trial 3');
    trials = types.core.TimeIntervals('description', 'trials', ...
        'colnames', {'start_time', 'stop_time'});
    trials.addRow('start_time', 0.0, 'stop_time', 1.0);
    trials.addRow('start_time', 2.0, 'stop_time', 3.0);
    trials.addRow('start_time', 4.0, 'stop_time', 5.0);
    trials.addRaggedArray('raw_data', ...
        {types.untyped.ObjectView(rawTrial1), [], types.untyped.ObjectView(rawTrial3)}, ...
        'description', 'raw data recorded during each trial');
    % end snippet
    references = trials.vectordata.get('raw_data').data;
    assert(numel(references) == 2 && references(1).target == rawTrial1 ...
        && references(2).target == rawTrial3)
    assert(isequal(trials.vectordata.get('raw_data_index').data(:).', uint64([1 1 2])))

    % snippet: flat-pixel-masks
    pixels = table(uint32([1; 2; 3; 7; 8]), uint32([4; 4; 4; 9; 9]), single(ones(5, 1)), ...
        'VariableNames', {'x', 'y', 'weight'});
    pixelsPerRoi = [3; 2];
    planeSegmentation = types.core.PlaneSegmentation('description', 'rois');
    planeSegmentation.addRaggedArray('pixel_mask', pixels, ...
        'ElementsPerRow', pixelsPerRoi, 'description', 'pixel masks');
    % end snippet
    assert(isequal(planeSegmentation.pixel_mask.data, [roi1; roi2]))
    assert(isequal(planeSegmentation.pixel_mask_index.data(:).', uint64([3 5])))

    % ---- Doubly-ragged, single electrode per unit ----
    % snippet: doubly-single-electrode
    unit1 = rand(40, 3);   % [numSamples x numSpikes]: 3 spikes
    unit2 = rand(40, 4);   % 4 spikes
    units = types.core.Units('colnames', {}, 'description', 'units');
    units.addRaggedArray('waveforms', {unit1, unit2}, ...
        'description', 'spike waveforms', 'Depth', 2);
    % end snippet
    assert(isequal(units.waveforms.data, [unit1, unit2]))
    assert(isequal(units.waveforms_index.data(:).', uint64(1:7)))
    assert(isequal(units.waveforms_index_index.data(:).', uint64([3 7])))

    % ---- Doubly-ragged, multiple channels per spike ----
    % snippet: doubly-multi-channel
    % One [numSamples x numElectrodes] matrix per spike: 2 spikes, then 3.
    m1 = {rand(40, 3), rand(40, 3)};
    m2 = {rand(40, 3), rand(40, 3), rand(40, 3)};
    units = types.core.Units('colnames', {}, 'description', 'units');
    units.addRaggedArray('waveforms', {m1, m2}, ...
        'description', 'multi-channel spike waveforms', 'Depth', 2);
    units.addRaggedArray('electrodes', {[0 1 2], [0 1 2]}, 'table', electrodesTable);
    % end snippet
    assert(isequal(size(units.waveforms.data), [numSamples, 15]))
    assert(isequal(units.waveforms.data(:, 4:6), m1{2}))
    assert(isequal(units.waveforms_index.data(:).', uint64([3 6 9 12 15])))
    assert(isequal(units.waveforms_index_index.data(:).', uint64([2 5])))

    % ---- Doubly-ragged, multiple channels per spike, array shortcut ----
    % snippet: doubly-multi-channel-array
    a1 = rand(40, 3, 2);   % [numSamples x numElectrodes x numSpikes]: 2 spikes
    a2 = rand(40, 3, 3);   % 3 spikes
    units = types.core.Units('colnames', {}, 'description', 'units');
    units.addRaggedArray('waveforms', {a1, a2}, ...
        'description', 'multi-channel spike waveforms', 'Depth', 2);
    % end snippet
    assert(isequal(size(units.waveforms.data), [numSamples, 15]))
    assert(isequal(units.waveforms_index.data(:).', uint64([3 6 9 12 15])))
    assert(isequal(units.waveforms_index_index.data(:).', uint64([2 5])))
    % Spike 2 of unit 1 is waveform columns 4:6; electrode 3 is the last of them.
    assert(isequal(units.waveforms.data(:, 6), a1(:, 3, 2)))

    % ---- Doubly-ragged, units with different electrode counts ----
    % snippet: doubly-mixed-electrode-counts
    b1 = rand(40, 3, 2);   % 2 spikes on 3 electrodes
    b2 = rand(40, 1, 4);   % 4 spikes on 1 electrode
    b3 = rand(40, 3);      % 1 spike on 3 electrodes
    units = types.core.Units('colnames', {}, 'description', 'units');
    units.addRaggedArray('waveforms', {b1, b2, b3}, ...
        'description', 'spike waveforms', 'Depth', 2);
    % end snippet
    assert(isequal(size(units.waveforms.data), [numSamples, 13]))
    assert(isequal(units.waveforms_index.data(:).', uint64([3 6 7 8 9 10 13])))
    assert(isequal(units.waveforms_index_index.data(:).', uint64([2 6 7])))
    assert(isequal(units.waveforms.data(:, 11:13), b3))

    % ---- Doubly-ragged, electrode count stated with ElementsPerSubGroup ----
    % snippet: doubly-elements-per-sub-group
    c1 = rand(40, 6);   % 2 spikes on 3 electrodes: 6 waveforms
    c2 = rand(40, 4);   % 4 spikes on 1 electrode: 4 waveforms
    c3 = rand(40, 3);   % 1 spike on 3 electrodes: 3 waveforms
    units = types.core.Units('colnames', {}, 'description', 'units');
    units.addRaggedArray('waveforms', {c1, c2, c3}, ...
        'description', 'spike waveforms', 'Depth', 2, ...
        'ElementsPerSubGroup', [3 1 3]);
    % end snippet
    assert(isequal(units.waveforms.data, [c1, c2, c3]))
    assert(isequal(units.waveforms_index.data(:).', uint64([3 6 7 8 9 10 13])))
    assert(isequal(units.waveforms_index_index.data(:).', uint64([2 6 7])))

    % snippet: helper-functions
    unit1 = rand(40, 3);   % [numSamples x numSpikes]: 3 spikes
    unit2 = rand(40, 4);   % 4 spikes
    [waveforms, waveformsIndex, waveformsIndexIndex] = ...
        util.create_indexed_column({unit1, unit2}, 'spike waveforms', 'Depth', 2);

    units = types.core.Units( ...
        'colnames', {'waveforms'}, ...
        'description', 'units', ...
        'waveforms', waveforms, ...
        'waveforms_index', waveformsIndex, ...
        'waveforms_index_index', waveformsIndexIndex, ...
        'id', types.hdmf_common.ElementIdentifiers('data', [0; 1]));
    % end snippet
    assert(isequal(units.waveforms_index_index.data(:).', uint64([3 7])))
end
