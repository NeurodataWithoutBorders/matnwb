classdef SpaceType
    %SPACETYPE Available space type
    
    properties
        string;
    end
    
    methods
        function obj = SpaceType(string)
            obj.string = string;
        end
    end
    
    enumeration
        Scalar('H5S_SCALAR');
        Simple('H5S_SIMPLE');
        Null('H5S_NULL');
    end
end

