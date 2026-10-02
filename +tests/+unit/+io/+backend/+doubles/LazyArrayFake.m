classdef LazyArrayFake < io.backend.base.LazyArray
% LazyArrayFake - In-memory LazyArray that records its load_mat_style calls.
%   Reads by indexing a MATLAB array and inherits every other method from
%   io.backend.base.LazyArray, so tests can exercise the default
%   implementations of the base class without a file.

    properties (SetAccess = private)
        % Data - The array that reads index into.
        Data

        % LoadMatStyleCount - Number of calls to load_mat_style.
        LoadMatStyleCount (1,1) double = 0

        % Selections - Subscripts of each load_mat_style call, one cell
        % array per call.
        Selections (1,:) cell = {}
    end

    methods
        function obj = LazyArrayFake(data)
            obj@io.backend.base.LazyArray(missing, missing, size(data), class(data));
            obj.Data = data;
        end

        function refreshSizeInfo(obj)
            obj.setSizeInfo(size(obj.Data), size(obj.Data));
        end

        function dataType = resolveDataType(obj)
            dataType = class(obj.Data);
        end

        function data = load_mat_style(obj, varargin)
            obj.LoadMatStyleCount = obj.LoadMatStyleCount + 1;
            obj.Selections{end+1} = varargin;
            data = obj.Data(varargin{:});
        end
    end
end
