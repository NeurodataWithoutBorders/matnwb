classdef Point < io.space.Shape
    %POINT index points of a selection
    
    properties
        index = 1;
    end
    
    methods
        function obj = Point(ind)
            validateattributes(ind, {'numeric'}, {'scalar', 'nonnegative'});
            obj.index = ind;
        end
    end
    
    %% io.space.Shape
    methods
        function [start, stride, count, block] = getSpaceSpec(obj)
            start = obj.index;
            stride = 1;
            count = 1;
            block = 1;
        end
        
        function varargout = getMatlabIndex(obj)
            if 0 == nargout
                return;
            end
            
            varargout{1} = obj.index;
        end
    end
end

