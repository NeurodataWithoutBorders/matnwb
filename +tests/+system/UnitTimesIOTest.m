classdef UnitTimesIOTest < tests.system.RoundTripTest
    methods
        function addContainer(~, file)
            file.units = types.core.Units( ...
                'colnames', {'spike_times', 'waveforms'}, 'description', 'test Units');
            
            file.units.addRow('spike_times', rand(), 'waveforms', rand());
            file.units.addRow('spike_times', rand(3,1), 'waveforms', rand(3,1));
            file.units.addRow('spike_times', rand(5,1), 'waveforms', {rand(5,1);rand(7,1)});
        end
        
        function c = getContainer(~, file)
            c = file.units.spike_times;
        end
    end
end