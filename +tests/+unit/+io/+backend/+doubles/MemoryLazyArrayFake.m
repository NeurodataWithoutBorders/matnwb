classdef MemoryLazyArrayFake < io.backend.base.LazyArray
% MemoryLazyArrayFake - Lazy array backed by an in-memory MATLAB array.
%
% The array is given in MatNWB's dimension order and kept in the storage
% order the fake is configured with, so readSubscripts and readPoints work
% on stored data the way a backend's reads do. The fake counts how many
% times each read is called.

    properties (SetAccess = private)
        % NumSubscriptReads - Number of readSubscripts calls.
        NumSubscriptReads (1,1) double = 0

        % NumPointReads - Number of readPoints calls.
        NumPointReads (1,1) double = 0
    end

    properties (Access = private)
        StoredData
        IsReversed (1,1) logical
        MaxOverread (1,1) double
        MinElements (1,1) double
    end

    methods
        function obj = MemoryLazyArrayFake(data, options)
            arguments
                data
                options.IsStorageOrderReversed (1,1) logical = false
                options.MaxBoundingBoxOverread (1,1) double = 1
                options.MinBoundingBoxElements (1,1) double = 0
            end
            obj@io.backend.base.LazyArray("in-memory", "/data");
            obj.IsReversed = options.IsStorageOrderReversed;
            obj.MaxOverread = options.MaxBoundingBoxOverread;
            obj.MinElements = options.MinBoundingBoxElements;
            dims = size(data);
            if iscolumn(data)
                dims = numel(data);
            end
            if obj.IsReversed && numel(dims) >= 2
                obj.StoredData = permute(data, numel(dims):-1:1);
            else
                obj.StoredData = data;
            end
            obj.setSizeInfo(dims, dims);
            obj.setDataTypeInfo(class(data));
        end

        function refreshSizeInfo(~)
        end
    end

    methods (Access = protected)
        function data = readSubscripts(obj, selection)
            obj.NumSubscriptReads = obj.NumSubscriptReads + 1;
            data = obj.StoredData(selection{:});
        end

        function values = readPoints(obj, subscripts)
            obj.NumPointReads = obj.NumPointReads + 1;
            if size(subscripts, 2) == 1
                values = obj.StoredData(subscripts);
            else
                columns = num2cell(subscripts, 1);
                values = obj.StoredData(sub2ind(size(obj.StoredData), columns{:}));
            end
            values = values(:);
        end

        function tf = isStorageOrderReversed(obj)
            tf = obj.IsReversed;
        end

        function [maxOverread, minElements] = getBoundingBoxLimits(obj)
            maxOverread = obj.MaxOverread;
            minElements = obj.MinElements;
        end
    end
end
