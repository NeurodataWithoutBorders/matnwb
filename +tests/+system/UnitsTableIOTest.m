classdef UnitsTableIOTest < tests.system.PyNWBIOTest
    properties (ClassSetupParameter)
        % Both addDoublyRaggedArray input forms must store the same waveforms
        % layout as PyNWB's Units.add_unit.
        WaveformInput = struct( ...
            "CellPerSpike", "cell", ...
            "ArrayPerUnit", "array")
    end

    properties (Access = private)
        WaveformInputForm (1,1) string = "cell"
    end

    methods (TestClassSetup)
        function setWaveformInput(testCase, WaveformInput)
            % Class setup runs before the method setup that calls addContainer.
            testCase.WaveformInputForm = WaveformInput;
        end
    end

    methods
        function addContainer(testCase, file)
            % Build a Units table with multi-electrode, doubly-ragged waveforms
            % using addRaggedArray. This mirrors PyNWB's Units.add_unit in
            % PyNWBIOTest.py so the two round-tripped containers compare equal.
            file.units = types.core.Units('description', 'data on spiking units');

            % spike_times: a ragged column, one list of times per unit.
            file.units.addRaggedArray('spike_times', {[1 2], [3 4 5]});

            % waveforms: a doubly-ragged column stored as a 2-D
            % [num_waveforms, num_samples] dataset, with the electrode dimension
            % carried by waveforms_index. Unit 1 has 2 spikes, unit 2 has 3
            % spikes; each spike has 2 electrodes and 3 samples. Both input
            % forms hold the same values as PyNWBIOTest.py, in MatNWB's
            % orientation: the schema's dimensions reversed, ragged axes last.
            switch testCase.WaveformInputForm
                case "cell"
                    % data{unit}{spike} is [num_samples x num_electrodes].
                    waveforms = { ...
                        {int32([1 4; 2 5; 3 6]), int32([7 10; 8 11; 9 12])}, ...
                        {int32([13 16; 14 17; 15 18]), int32([19 22; 20 23; 21 24]), int32([25 28; 26 29; 27 30])} ...
                        };
                case "array"
                    % data{unit} is [num_samples x num_electrodes x num_spikes].
                    % numpy's row-major reshape(num_spikes, num_electrodes,
                    % num_samples) and MATLAB's column-major reshape with the
                    % dimensions reversed lay out the values identically.
                    waveforms = { ...
                        reshape(int32(1:12), 3, 2, 2), ...
                        reshape(int32(13:30), 3, 2, 3) ...
                        };
                otherwise
                    error("Unknown WaveformInput value ""%s"".", testCase.WaveformInputForm)
            end
            file.units.addRaggedArray('waveforms', waveforms, 'Depth', 2);

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
            file.units.waveforms_sampling_rate = 1;
        end

        function c = getContainer(~, file)
            c = file.units;
        end
    end
end
