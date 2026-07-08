classdef UnitTimesIOTest < tests.system.PyNWBIOTest
    methods
        function addContainer(~, file)
            % Build a Units table with multi-electrode, doubly-ragged waveforms
            % using the idiomatic addRaggedArray / addDoublyRaggedArray methods.
            % This mirrors PyNWB's Units.add_unit in PyNWBIOTest.py so the two
            % round-tripped containers compare equal.
            file.units = types.core.Units('description', 'data on spiking units');

            % spike_times: a ragged column, one list of times per unit.
            file.units.addRaggedArray('spike_times', {[1 2], [3 4 5]});

            % waveforms: a doubly-ragged column. data{unit}{spike} is a
            % [numWaveforms x numSamples] matrix (one waveform per electrode).
            % Unit 1 has 2 spikes, unit 2 has 3 spikes; each spike has 2
            % electrodes and 3 samples.
            waveforms = { ...
                {int32([1 2 3; 4 5 6]), int32([7 8 9; 10 11 12])}, ...
                {int32([13 14 15; 16 17 18]), int32([19 20 21; 22 23 24]), int32([25 26 27; 28 29 30])} ...
                };
            file.units.addDoublyRaggedArray('waveforms', waveforms);

            % waveform_mean / waveform_sd: fixed 2-D columns [numSamples x numUnits].
            file.units.waveform_mean = types.hdmf_common.VectorData( ...
                'description', 'the spike waveform mean for each spike unit', ...
                'data', [1 4; 2 5; 3 6]);
            file.units.waveform_sd = types.hdmf_common.VectorData( ...
                'description', 'the spike waveform standard deviation for each spike unit', ...
                'data', [7 10; 8 11; 9 12]);

            % Match PyNWB's column order and auto-generated descriptions so the
            % round-tripped containers compare equal.
            file.units.colnames = {'spike_times'; 'waveform_mean'; 'waveform_sd'; 'waveforms'};
            file.units.spike_times.description = 'the spike times for each unit in seconds';
            file.units.spike_times_index.description = 'Index for VectorData ''spike_times''';
            file.units.waveforms.description = ['Individual waveforms for each spike. ' ...
                'If the dataset is three-dimensional, the third dimension shows the response ' ...
                'from different electrodes that all observe this unit simultaneously. ' ...
                'In this case, the `electrodes` column of this Units table should be used to ' ...
                'indicate which electrodes are associated with this unit, ' ...
                'and the electrodes dimension here should be in the same order as the ' ...
                'electrodes referenced in the `electrodes` column of this table.'];
            file.units.waveforms_index.description = 'Index for VectorData ''waveforms''';
            file.units.waveforms_index_index.description = 'Index for VectorData ''waveforms_index''';

            % Optional Units dataset attributes (match PyNWB waveform_rate / resolution).
            file.units.spike_times_resolution = 3;
            file.units.waveform_mean_sampling_rate = 1;
            file.units.waveform_sd_sampling_rate = 1;

            % Skip waveforms_sampling_rate because PyNWB does not export it.
            file.units.waveforms_sampling_rate = 1;
        end

        function c = getContainer(~, file)
            c = file.units;
        end
    end
end
