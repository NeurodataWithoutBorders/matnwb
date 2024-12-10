classdef Shape
    %SHAPE interface for H5S selection shapes
    
    methods (Abstract)
        % GETSPACESPEC returns arguments necessary for
        % the given dimension space to be used for
        % select_hyperslab()
        [start, stride, count, block] = getSpaceSpec(obj);
    end
end

