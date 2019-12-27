classdef IsConstant
    %ISCONSTANT This enum is a H5ML constant
    
    properties (SetAccess = immutable)
        id;
    end
    
    methods
        function obj = IsConstant(name)
            obj.id = H5ML.get_constant_value(name);
        end
    end
end

