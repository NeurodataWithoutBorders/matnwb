classdef LazyArray < handle
% LazyArray - Base class for backend-specific lazy dataset access.
%
% DataStub owns the public lazy dataset API exposed by MatNWB, while
% LazyArray implementations encapsulate storage-specific metadata
% discovery and indexed reads.

    properties (SetAccess = protected)
        % Filename - The path name of a file containing the dataset
        % wrapped by this LazyArray object.
        Filename (1,1) string

        % DatasetPath - The path name of the dataset wrapped by this LazyArray 
        % object relative to the root of the file.
        DatasetPath (1,1) string
    end

    properties (Dependent, SetAccess = private)
        dims
        maxDims
        dataType
    end

    properties (Access = protected)
        dims_ double = []
        maxDims_ double = []
        dataType_ = []
    end

    methods % Constructor and property getters.
        function obj = LazyArray(filename, path, dims, dataType)
            arguments
                filename (1,1) string = missing
                path (1,1) string = missing
                dims double = []
                dataType = []
            end

            obj.Filename = filename;
            obj.DatasetPath = path;

            if ~isempty(dims)
                obj.setSizeInfo(dims, obj.maxDims_);
            end
            if ~isempty(dataType)
                obj.setDataTypeInfo(dataType);
            end
        end

        function dims = get.dims(obj)
            if isempty(obj.dims_)
                obj.refreshSizeInfo();
            end
            dims = obj.dims_;
        end

        function maxDims = get.maxDims(obj)
            if isempty(obj.maxDims_)
                obj.refreshSizeInfo();
            end
            maxDims = obj.maxDims_;
        end

        function dataType = get.dataType(obj)
            if isempty(obj.dataType_)
                obj.setDataTypeInfo(obj.resolveDataType());
            end
            dataType = obj.dataType_;
        end
    end

    methods % Should be implemented by subclasses
        function refreshSizeInfo(obj) %#ok<MANU>
            io.backend.base.LazyArray.throwNotImplemented("refreshSizeInfo")
        end

        function dataType = resolveDataType(obj) %#ok<MANU>
            dataType = [];
            io.backend.base.LazyArray.throwNotImplemented("resolveDataType")
        end

        function data = load_h5_style(obj, varargin) %#ok<INUSD>
            data = [];
            io.backend.base.LazyArray.throwNotImplemented("load_h5_style")
        end

        function data = load_mat_style(obj, varargin) %#ok<INUSD>
            data = [];
            io.backend.base.LazyArray.throwNotImplemented("load_mat_style")
        end
    end

    methods (Access = protected)
        function setSizeInfo(obj, dims, maxDims)
            obj.dims_ = dims;
            obj.maxDims_ = maxDims;
        end

        function setDataTypeInfo(obj, dataType)
            if isstring(dataType) || ischar(dataType)
                obj.dataType_ = char(dataType);
            else
                obj.dataType_ = dataType;
            end
        end
    end

    methods % Can be overridden by subclasses
        function data = loadSelections(obj, selections)
        % loadSelections - Read several selections, each as load_mat_style would.
        %
        % This implementation calls load_mat_style once per selection.
        % Backends that can read several selections in one pass over the
        % dataset override it.
        %
        % Input Arguments:
        %   obj        - LazyArray instance to read from.
        %   selections - Cell array with one cell array of subscripts per
        %                selection, for example {{':', 1:3}, {':', 7:9}}.
        %
        % Output Arguments:
        %   data - Cell array of the same size as selections, with the data
        %          of each selection.

            data = cell(size(selections));
            for iSelection = 1:numel(selections)
                data{iSelection} = obj.load_mat_style(selections{iSelection}{:});
            end
        end
    end

    methods (Static, Access = private)
        function throwNotImplemented(methodName)
            error("NWB:Backend:LazyArray:NotImplemented", ...
                "LazyArray method `%s` is not implemented.", methodName)
        end
    end
end
