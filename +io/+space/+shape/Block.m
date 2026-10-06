classdef Block < io.space.Shape
    %BLOCK Shape indicating a non-scalar hyperslab selection
    
    properties
        start = 1;
        step = 1;
        stop = 1;
    end
    
    properties(SetAccess=private, Dependent)
        length;
        range;
    end
    
    methods
        function obj = Block(options)
            % The selection of a dataset with many runs builds thousands of
            % blocks, so the constructor validates with an arguments block,
            % which costs a few microseconds per call.
            arguments
                options.start (1,1) {mustBeNumeric, mustBeNonnegative} = 1
                options.step (1,1) {mustBeNumeric, mustBeNonnegative} = 1
                options.stop (1,1) {mustBeNumeric, mustBeNonnegative} = 1
            end
            obj.start = options.start;
            obj.step = options.step;
            obj.stop = options.stop;
        end
    end
    
    methods % set/get
        function r = get.range(obj)
            r = obj.start:obj.step:obj.stop;
        end
        function l = get.length(obj)
            l = length(obj.range);
        end
    end
    %% datastub.Shape
    methods
        function [start, stride, count, block] = getSpaceSpec(obj)
            start = obj.start;
            if obj.step == 1
                % special case where our hyperslab is defined
                % by a single block.
                stride = 1;
                count = 1;
                block = obj.length;
            else
                stride = obj.step;
                count = obj.length;
                block = 1;
            end
        end
    end
end
