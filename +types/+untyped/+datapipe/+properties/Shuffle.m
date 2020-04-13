classdef Shuffle < types.untyped.datapipe.Properties
    %SHUFFLE Shuffle Filter
    
    properties (Constant)
        FILTER_NAME = 'H5Z_FILTER_SHUFFLE';
    end
    
    %% Filter
    methods
        function addTo(~, dcpl)
            H5P.set_shuffle(dcpl);
        end
        
        function name = getName(~)
            name = 'shuffle';
        end
        
        function tf = isInPropertyList(obj, dcpl)
            import types.untyped.datapipe.properties.Shuffle;
            
            tf = false;
            filterId = H5ML.get_constant_value(dcpl, Shuffle.FILTER_NAME);
            for i = 0:(H5P.get_nfilters(dcpl) - 1)
                [id, ~, ~, ~, ~] = H5P.get_filter(dcpl, i);
                if id == filterId
                    tf = true;
                    return;
                end
            end
        end
    end
end

