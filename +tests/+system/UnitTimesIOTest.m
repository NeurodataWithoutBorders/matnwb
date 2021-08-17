classdef UnitTimesIOTest < tests.system.RoundTripTest
    methods
        function addContainer(~, file)
            vdata = rand(10,1);
            file.units = types.core.Units('description', 'test Units', 'colnames', {'spike_times'});
            file.units.addRow('spike_times', vdata(1));
            file.units.addRow('spike_times', vdata(2:5));
            file.units.addRow('spike_times', vdata(6:end));
        end
        
        function c = getContainer(~, file)
            c = file.units.spike_times;
        end
    end
end