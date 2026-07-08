function ragged_arrays_examples()
% ragged_arrays_examples - Runnable snippets for the "Storing Ragged and
% Doubly-Ragged Array Columns" how-to guide.
%
% Each region between "% snippet: <name>" and "% end snippet" markers is
% embedded into docs/source/pages/how_to/ragged_arrays.rst via literalinclude.
% The assertions keep the guide's code correct: this function is executed by
% tests/unit/howToRaggedArrayExamplesTest.

    electrodesTable = local_electrodesTable();

    % snippet: ragged-spike-times
    units = types.core.Units('colnames', {}, 'description', 'units');
    units.addRaggedArray('spike_times', {[0.1 0.2 0.3], [0.5 0.6]}, ...
        'description', 'spike times');
    % end snippet
    assert(isequal(units.spike_times_index.data(:).', uint64([3 5])))

    % snippet: ragged-electrodes-region
    units.addRaggedArray('electrodes', {[0 1 2], [0 1 2]}, 'table', electrodesTable);
    % end snippet
    assert(isa(units.electrodes, 'types.hdmf_common.DynamicTableRegion'))

    % ---- Doubly-ragged, single electrode per unit ----
    % Each unit's matrix is [numWaveforms x numSamples]; with one electrode,
    % numWaveforms is the number of spikes.
    numSamples = 40;
    unit1 = rand(3, numSamples);   % 3 spikes
    unit2 = rand(4, numSamples);   % 4 spikes

    % snippet: doubly-single-electrode
    units = types.core.Units('colnames', {}, 'description', 'units');
    units.addDoublyRaggedArray('waveforms', {unit1, unit2}, ...
        'description', 'spike waveforms');
    % end snippet
    assert(isequal(units.waveforms_index.data(:).', uint64(1:7)))
    assert(isequal(units.waveforms_index_index.data(:).', uint64([3 7])))

    % ---- Doubly-ragged, multiple channels per spike ----
    % Each spike's matrix is [numWaveforms x numSamples]; with several
    % electrodes, numWaveforms is the number of electrodes.
    numElectrodes = 3;
    m1 = { rand(numElectrodes, numSamples), rand(numElectrodes, numSamples) };
    m2 = { rand(numElectrodes, numSamples), rand(numElectrodes, numSamples), rand(numElectrodes, numSamples) };

    % snippet: doubly-multi-channel
    units = types.core.Units('colnames', {}, 'description', 'units');
    units.addDoublyRaggedArray('waveforms', {m1, m2}, ...
        'description', 'multi-channel spike waveforms');
    units.addRaggedArray('electrodes', {[0 1 2], [0 1 2]}, 'table', electrodesTable);
    % end snippet
    assert(isequal(size(units.waveforms.data), [numSamples, 15]))
    assert(isequal(units.waveforms_index.data(:).', uint64([3 6 9 12 15])))
    assert(isequal(units.waveforms_index_index.data(:).', uint64([2 5])))

    % snippet: helper-functions
    [waveforms, waveformsIndex, waveformsIndexIndex] = ...
        util.create_doubly_indexed_column({unit1, unit2}, 'spike waveforms');

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

function electrodesTable = local_electrodesTable()
    % Minimal electrodes table for the DynamicTableRegion examples.
    device = types.core.Device();
    group = types.core.ElectrodeGroup( ...
        'description', 'example group', 'location', 'cortex', ...
        'device', types.untyped.SoftLink(device));
    groupView = types.untyped.ObjectView(group);
    electrodesTable = types.core.ElectrodesTable( ...
        'colnames', {'location', 'group', 'group_name'}, ...
        'description', 'electrodes', ...
        'location', types.hdmf_common.VectorData('description', 'location', ...
            'data', {'cortex'; 'cortex'; 'cortex'}), ...
        'group', types.hdmf_common.VectorData('description', 'group', ...
            'data', [groupView; groupView; groupView]), ...
        'group_name', types.hdmf_common.VectorData('description', 'group name', ...
            'data', {'g'; 'g'; 'g'}), ...
        'id', types.hdmf_common.ElementIdentifiers('data', (0:2)'));
end
