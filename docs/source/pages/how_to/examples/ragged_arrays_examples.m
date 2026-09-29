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
    % Each unit's matrix is [numSamples x numWaveforms], one waveform per
    % column; with one electrode, numWaveforms is the number of spikes.
    numSamples = 40;
    unit1 = rand(numSamples, 3);   % 3 spikes
    unit2 = rand(numSamples, 4);   % 4 spikes

    % snippet: doubly-single-electrode
    units = types.core.Units('colnames', {}, 'description', 'units');
    units.addRaggedArray('waveforms', {unit1, unit2}, ...
        'description', 'spike waveforms', 'Depth', 2);
    % end snippet
    assert(isequal(units.waveforms.data, [unit1, unit2]))
    assert(isequal(units.waveforms_index.data(:).', uint64(1:7)))
    assert(isequal(units.waveforms_index_index.data(:).', uint64([3 7])))

    % ---- Doubly-ragged, multiple channels per spike ----
    % Each spike's matrix is [numSamples x numWaveforms]; with several
    % electrodes, numWaveforms is the number of electrodes.
    numElectrodes = 3;
    m1 = { rand(numSamples, numElectrodes), rand(numSamples, numElectrodes) };
    m2 = { rand(numSamples, numElectrodes), rand(numSamples, numElectrodes), rand(numSamples, numElectrodes) };

    % snippet: doubly-multi-channel
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
    % When every spike of a unit was recorded on the same electrodes, the
    % unit's waveforms fit in one [numSamples x numElectrodes x numSpikes]
    % array: the (numSpikes, numElectrodes, numSamples) array PyNWB's
    % Units.add_unit takes, with the dimensions reversed.
    a1 = rand(numSamples, numElectrodes, 2);   % 2 spikes
    a2 = rand(numSamples, numElectrodes, 3);   % 3 spikes

    % snippet: doubly-multi-channel-array
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
    % Once any unit is 3-D, every unit is read as [numSamples x numElectrodes
    % x numSpikes]: a single electrode is [numSamples x 1 x numSpikes], and a
    % matrix is a unit with one spike.
    b1 = rand(numSamples, 3, 2);   % 2 spikes on 3 electrodes
    b2 = rand(numSamples, 1, 4);   % 4 spikes on 1 electrode
    b3 = rand(numSamples, 3);      % 1 spike on 3 electrodes

    % snippet: doubly-mixed-electrode-counts
    units = types.core.Units('colnames', {}, 'description', 'units');
    units.addRaggedArray('waveforms', {b1, b2, b3}, ...
        'description', 'spike waveforms', 'Depth', 2);
    % end snippet
    assert(isequal(size(units.waveforms.data), [numSamples, 13]))
    assert(isequal(units.waveforms_index.data(:).', uint64([3 6 7 8 9 10 13])))
    assert(isequal(units.waveforms_index_index.data(:).', uint64([2 6 7])))
    assert(isequal(units.waveforms.data(:, 11:13), b3))

    % snippet: helper-functions
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
