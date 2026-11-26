function ragged_arrays_examples()
% ragged_arrays_examples - Runnable snippets for the "Storing Ragged and
% Doubly-Ragged Array Columns" how-to guide.
%
% Each region between "% snippet: <name>" and "% end snippet" markers is
% embedded into docs/source/pages/how_to/ragged_arrays.rst via literalinclude.
% The snippets appear here in the order of the guide, and together they
% define every variable they use, so a reader can run the guide from top to
% bottom. The assertions between the snippets keep the guide's code correct.
% tests/unit/HowToRaggedArrayExamplesTest runs this function, and runs the
% snippets on their own.

    numSamples = 40;   % for the assertions; the snippets state it as 40

    % snippet: ragged-spike-times
    units = types.core.Units('colnames', {}, 'description', 'units');
    units.addRaggedArray('spike_times', {[0.1 0.2 0.3], [0.5 0.6]}, ...
        'Description', 'spike times');
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
    units.addRaggedArray('electrodes', {[0 1 2], [0 1 2]}, 'TargetTable', electrodesTable);
    % end snippet
    assert(isa(units.electrodes, 'types.hdmf_common.DynamicTableRegion'))

    % ---- Doubly-ragged, multiple channels per spike ----
    % snippet: doubly-multi-channel
    % One [numSamples x numElectrodes] matrix per spike: 2 spikes, then 3.
    m1 = {rand(40, 3), rand(40, 3)};
    m2 = {rand(40, 3), rand(40, 3), rand(40, 3)};
    units = types.core.Units('colnames', {}, 'description', 'units');
    units.addRaggedArray('waveforms', {m1, m2}, ...
        'Description', 'multi-channel spike waveforms', 'Depth', 2);
    units.addRaggedArray('electrodes', {[0 1 2], [0 1 2]}, 'TargetTable', electrodesTable);
    % end snippet
    assert(isequal(size(units.waveforms.data), [numSamples, 15]))
    assert(isequal(units.waveforms.data(:, 4:6), m1{2}))
    assert(isequal(units.waveforms_index.data(:).', uint64([3 6 9 12 15])))
    assert(isequal(units.waveforms_index_index.data(:).', uint64([2 5])))

    % snippet: helper-functions
    % One [numSamples x numElectrodes] matrix per spike: 2 spikes, then 3.
    spikes1 = {rand(40, 3), rand(40, 3)};
    spikes2 = {rand(40, 3), rand(40, 3), rand(40, 3)};
    [waveforms, waveformsIndex, waveformsIndexIndex] = ...
        util.create_indexed_column({spikes1, spikes2}, 'spike waveforms', 'Depth', 2);

    units = types.core.Units( ...
        'colnames', {'waveforms'}, ...
        'description', 'units', ...
        'waveforms', waveforms, ...
        'waveforms_index', waveformsIndex, ...
        'waveforms_index_index', waveformsIndexIndex, ...
        'id', types.hdmf_common.ElementIdentifiers('data', [0; 1]));
    % end snippet
    assert(isequal(units.waveforms_index_index.data(:).', uint64([2 5])))
end
