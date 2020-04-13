classdef Property < handle
    %PROPERTY used in datapipe creation
    
    methods (Abstract)
        addTo(obj, dcpl);
        name = getName(obj);
        tf = isInDcpl(obj, dcpl);
    end
end