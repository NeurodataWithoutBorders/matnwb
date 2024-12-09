classdef Property < handle & matlab.mixin.Heterogeneous
    %PROPERTY used in datapipe creation
    
    methods (Static, Abstract)
        tf = isInDcpl(dcpl);
    end
    
    methods (Abstract)
        addTo(obj, dcpl);
    end
end
