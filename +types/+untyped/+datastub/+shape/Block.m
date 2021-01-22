classdef Block < types.untyped.datastub.Shape
    %BLOCK Shape indicating a non-scalar hyperslab selection
    
    properties
        start = 0;
        step = 1;
        stop = 0; % note, inclusive zero-indexed by default
    end
    
    properties(SetAccess=private, Dependent)
        length;
        range;
    end
    
    methods
        function obj = Block(varargin)
            p = inputParser;
            addParameter(p, 'start', 0, @(x)isscalar(x) && isnumeric(x) && x >= 0);
            addParameter(p, 'step', 1, @(x)isscalar(x) && isnumeric(x) && x >= 0);
            addParameter(p, 'stop', 1, @(x)isscalar(x) && isnumeric(x) && x >= 0);
            parse(p, varargin{:});
            obj.start = p.Results.start;
            obj.step = p.Results.step;
            obj.stop = p.Results.stop;
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