classdef Point < types.untyped.datastub.Shape
    %POINT index points of a selection
    
    properties
        index = 0;
    end
    
    methods
        function obj = Point(ind)
            validateattributes(ind, {'numeric'}, {'scalar', 'nonnegative'});
            obj.index = ind;
        end
    end
    
    %% datastub.Shape
    methods
        function [start, stride, count, block] = getSpaceSpec(obj)
            start = obj.index;
            stride = 1;
            count = 1;
            block = 1;
        end
    end
end

