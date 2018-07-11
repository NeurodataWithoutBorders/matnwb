classdef UnitTimesIOTest < tests.system.RoundTripTest
    methods
        function addContainer(~, file)
            vd = types.core.VectorData('data', rand(10, 1));
            
            vd_ref = types.untyped.RegionView( ...
                '/acquisition/test_uT/spike_times', {[9 10]});
            vi = types.core.VectorIndex('data', vd_ref);
            ei = types.core.ElementIdentifiers('data', int64(1));
            ut = types.core.UnitTimes('spike_times', vd, ...
                'spike_times_index', vi, 'unit_ids', ei);
            
            file.acquisition.set('test_uT', ut);
        end
        
        function c = getContainer(~, file)
            c = file.acquisition.get('test_uT');
        end
    end
end