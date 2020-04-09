classdef Shuffle < types.untyped.datapipe.Filter
    %SHUFFLE Shuffle Filter
    
    methods % Filter
        function addTo(~, dcpl)
            H5P.set_shuffle(dcpl);
        end
        
        function name = getName(~)
            name = 'shuffle';
        end
    end
end

