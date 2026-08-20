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
        % refreshSizeInfo - Read the dataset's current size from the backend.
        %
        % Implementations query the storage backend for the dataset's
        % dimensions and report them by calling setSizeInfo, which populates
        % the dims and maxDims properties. Dimensions are reported in MatNWB's
        % H5-style order, which backends storing row-major shapes must reverse.
        %
        % Input Arguments:
        %   obj - LazyArray instance whose size information is refreshed.

            io.backend.base.LazyArray.throwNotImplemented("refreshSizeInfo")
        end

        function dataType = resolveDataType(obj) %#ok<MANU>
        % resolveDataType - Determine the MATLAB type of the dataset values.
        %
        % Called on first access to the dataType property. For a compound
        % dataset, implementations return a type descriptor struct mapping
        % each field name to its MATLAB class name, as expected by
        % types.util.checkDtype and types.untyped.DataStub.isCompoundType.
        %
        % Input Arguments:
        %   obj - LazyArray instance whose data type is resolved.
        %
        % Output Arguments:
        %   dataType - MATLAB class name, or a compound type descriptor struct.

            dataType = [];
            io.backend.base.LazyArray.throwNotImplemented("resolveDataType")
        end

        function data = load_h5_style(obj, varargin) %#ok<INUSD>
        % load_h5_style - Read data using HDF5-style start/count/stride.
        %
        % Called with no arguments, implementations return the whole dataset.
        % Called with start and count, and optionally stride, they return the
        % selected hyperslab; start is one-based and a count of Inf reads to
        % the end of that dimension.
        %
        % Input Arguments:
        %   obj      - LazyArray instance to read from.
        %   varargin - Empty, or start and count vectors with optional stride.
        %
        % Output Arguments:
        %   data - The selected data, in MatNWB's H5-style dimension order.

            data = [];
            io.backend.base.LazyArray.throwNotImplemented("load_h5_style")
        end

        function data = load_mat_style(obj, varargin) %#ok<INUSD>
        % load_mat_style - Read data using MATLAB-style subscript indexing.
        %
        % Implementations accept the subscripts of an indexing expression,
        % including ':' for a whole dimension, and return the selected
        % elements. Called with no arguments they return the whole dataset. A
        % compound dataset is returned as a table.
        %
        % Input Arguments:
        %   obj      - LazyArray instance to read from.
        %   varargin - Subscripts, one per indexed dimension.
        %
        % Output Arguments:
        %   data - The selected data, or a table for a compound dataset.

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

    methods (Static, Access = private)
        function throwNotImplemented(methodName)
            error("NWB:Backend:LazyArray:NotImplemented", ...
                "LazyArray method `%s` is not implemented.", methodName)
        end
    end
end
