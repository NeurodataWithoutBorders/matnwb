classdef IsConstant
    %ISCONSTANT This enum is a H5ML constant
    
    properties (SetAccess = immutable)
        constant;
    end
    
    methods
        function obj = IsConstant(name)
            obj.constant = H5ML.get_constant_value(name);
        end
    end
end

