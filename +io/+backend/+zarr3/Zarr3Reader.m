classdef Zarr3Reader < io.backend.base.Reader
    % Zarr3Reader - Reader implementation for local Zarr v3 stores.
    %
    % This reader is backed by the zarr-matlab package
    % (https://github.com/catalystneuro/zarr-matlab), which must be on the
    % MATLAB path, and reads Zarr v3 stores natively in MATLAB (no Python
    % dependency). It pairs with io.backend.zarr3.Zarr3Writer for writing.
    %
    % Object references are represented as an attribute value struct
    % `struct('zarr_dtype', "object", 'value', struct('path', targetPath))`,
    % matching the convention used by hdmf-zarr for Zarr v2 stores. There is no published Zarr v3 convention for NWB, but
    % this matches the "zarr_dtype" reference convention used by real
    % hdmf-zarr-style Zarr v3 NWB exports (verified against example files),
    % as well as the reader/writer pair's own round-trips.
    %
    % A dataset whose elements are themselves object references (e.g. a
    % DynamicTable column of ElectrodeGroup references) is represented on
    % disk as a plain Zarr "string" array whose elements are the same
    % reference JSON, tagged via a "zarr_dtype":"object" attribute on the
    % array itself (see io.internal.zarr3.buildNodeInfo); each element is
    % decoded into a types.untyped.ObjectView object array.
    %
    % A compound (struct/table) dataset -- a Zarr v3 "structured" data_type,
    % e.g. PlaneSegmentation's pixel_mask/voxel_mask, or
    % TimeSeriesReferenceVectorData's response/stimulus columns -- is backed
    % by io.backend.zarr3.Zarr3LazyArray; a field tagged "object" via the
    % array's "zarr_dtype" attribute (see
    % io.internal.zarr3.getCompoundFieldSemantics) is decoded into a
    % types.untyped.ObjectView, matching the plain object-reference-array
    % convention above. Requires zarr-matlab to support the Zarr v3
    % "structured" and "fixed_length_utf32" data types, which are unstable,
    % unspecified zarr-python extensions -- see
    % zarr.internal.dtype_info in zarr-matlab.

    properties (Access = private)
        RootGroup = []
        RootInfoCache = []
        NodeInfoMap = containers.Map('KeyType', 'char', 'ValueType', 'any')
    end

    methods
        function obj = Zarr3Reader(filename)
            obj@io.backend.base.Reader(filename);
        end

        function version = getSchemaVersion(obj)
            obj.ensureMetadataCache();
            attributes = obj.RootGroup.attrs;
            if isfield(attributes, "nwb_version")
                version = string(attributes.nwb_version);
            else
                error("NWB:Zarr3Reader:MissingSchemaVersion", ...
                    "The Zarr store `%s` does not define `nwb_version` in the root attributes.", ...
                    obj.Filename)
            end
        end

        function specLocation = getEmbeddedSpecLocation(obj)
            obj.ensureMetadataCache();
            attributes = obj.RootGroup.attrs;
            if isfield(attributes, "x_specloc")
                specLocation = string(attributes.x_specloc);
            elseif obj.RootGroup.isKey("specifications")
                specLocation = "/specifications";
            else
                specLocation = "";
            end

            if specLocation ~= "" && ~startsWith(specLocation, "/")
                specLocation = "/" + specLocation;
            end
        end

        function node = readRootInfo(obj)
            obj.ensureMetadataCache();
            node = obj.RootInfoCache;
        end

        function node = readNodeInfo(obj, nodePath)
            arguments
                obj
                nodePath (1,1) string
            end

            obj.ensureMetadataCache();
            normalizedPath = obj.normalizeNodePath(nodePath);
            if ~isKey(obj.NodeInfoMap, normalizedPath)
                error("NWB:Zarr3Reader:NodeNotFound", ...
                    "Node `%s` was not found in `%s`.", normalizedPath, obj.Filename)
            end
            node = obj.NodeInfoMap(normalizedPath);
        end

        function attributeValue = readAttributeValue(~, attributeInfo, ~)
            if (ischar(attributeInfo.Datatype) || isstring(attributeInfo.Datatype)) ...
                    && strcmp(attributeInfo.Datatype, "object reference")
                attributeValue = types.untyped.ObjectView(attributeInfo.Value.value.path);
            else
                attributeValue = attributeInfo.Value;
            end
        end

        function datasetValue = readDatasetValue(obj, datasetInfo, datasetPath)
            dataDimensions = obj.getDatasetDims(datasetInfo);
            isObjectReferenceArray = strcmp(datasetInfo.Datatype, "object");
            isStructuredArray = strcmp(datasetInfo.Datatype, "structured");
            % A true rank-0 array (this reader's own Zarr3Writer's scalar
            % convention) or one explicitly marked "scalar" by hdmf-zarr's
            % zarr_dtype hint (see io.internal.zarr3.buildNodeInfo) is read
            % eagerly. Dataspace.Size == 1 alone is NOT a reliable scalar
            % signal: hdmf-zarr represents a genuine NWB scalar property as
            % a rank-1, length-1 array, which is indistinguishable by shape
            % from a one-row VectorData column (e.g. a DynamicTable with a
            % single row) -- collapsing the latter to a bare value would
            % silently corrupt it (a char column's character count would
            % be misread as its row count downstream).
            isScalarMarked = isempty(dataDimensions) || strcmp(datasetInfo.Datatype, "scalar");
            if isObjectReferenceArray
                datasetValue = obj.readObjectArrayValue(datasetPath);
            elseif isStructuredArray
                % Checked ahead of the scalar/eager branch below: a
                % structured array can have prod(dataDimensions) == 1 (a
                % single record, e.g. shape [1]) without being a "scalar"
                % dataset in the ordinary sense.
                datasetValue = obj.readStructuredValue(datasetPath, dataDimensions);
            elseif isScalarMarked
                datasetValue = obj.readEagerValue(datasetPath);
            elseif any(dataDimensions == 0)
                datasetValue = [];
            else
                matlabDataType = io.internal.zarr3.getMatlabDataType(datasetInfo.Datatype);
                lazyArray = io.backend.zarr3.Zarr3LazyArray(...
                    obj.Filename, datasetPath, dataDimensions, matlabDataType);
                datasetValue = types.untyped.DataStub(...
                    obj.Filename, datasetPath, [], [], lazyArray);
            end
        end
    end

    methods (Access = private)
        function ensureMetadataCache(obj)
            if isempty(obj.RootGroup)
                io.backend.zarr3.internal.ensureAvailable()
                obj.RootGroup = zarr.open(obj.Filename);
                [obj.RootInfoCache, obj.NodeInfoMap] = io.internal.zarr3.buildNodeInfo(obj.RootGroup);
                obj.RootInfoCache.Filename = char(obj.Filename);
            end
        end

        function normalizedPath = normalizeNodePath(~, nodePath)
            normalizedPath = char(nodePath);
            if isempty(normalizedPath)
                normalizedPath = '/';
            elseif normalizedPath(1) ~= '/'
                normalizedPath = ['/' normalizedPath];
            end
        end

        function dataDimensions = getDatasetDims(~, datasetInfo)
            % Dataspace.Size is the raw (Zarr/numpy-order) shape; reverse it
            % for rank >= 2 to match MatNWB's H5-style dims convention (see
            % io.internal.zarr3.normalizeDatasetDimensions).
            if isfield(datasetInfo, "Dataspace") && isfield(datasetInfo.Dataspace, "Size")
                dataDimensions = double(datasetInfo.Dataspace.Size);
            else
                dataDimensions = [];
            end

            if numel(dataDimensions) >= 2
                dataDimensions = fliplr(dataDimensions);
            end
        end

        function datasetValue = readEagerValue(obj, datasetPath)
            relativePath = io.internal.zarr3.stripLeadingSlash(datasetPath);
            arrayNode = zarr.open(obj.Filename, Path=relativePath);
            datasetValue = arrayNode.read();

            if isstring(datasetValue) && isscalar(datasetValue)
                datasetValue = char(datasetValue);
            elseif iscell(datasetValue) && isscalar(datasetValue)
                datasetValue = datasetValue{1};
            end
        end

        function datasetValue = readStructuredValue(obj, datasetPath, dataDimensions)
            % readStructuredValue - Wrap a "structured" (compound) array in
            % a DataStub backed by io.backend.zarr3.Zarr3LazyArray. The
            % DataStub's dataType is a compound type descriptor struct
            % (field name -> MATLAB class name, or 'types.untyped.ObjectView'
            % for a field tagged as a reference via the array's own
            % "zarr_dtype" attribute; see
            % io.internal.zarr3.getCompoundTypeDescriptor) rather than a
            % plain class name, matching what
            % types.util.checkDtype/types.untyped.DataStub.isCompoundType
            % expect -- this alone is enough for schema validation to
            % succeed without loading any data (see
            % types.util.checkDtype>checkDtypeForCompoundDataset's
            % DataStub fast path).

            relativePath = io.internal.zarr3.stripLeadingSlash(datasetPath);
            arrayNode = zarr.open(obj.Filename, Path=relativePath);
            info = zarr.internal.dtype_info(arrayNode.meta.dataType, arrayNode.meta.dataTypeConfig);
            fieldSemantics = io.internal.zarr3.getCompoundFieldSemantics(arrayNode.attrs);
            typeDescriptor = io.internal.zarr3.getCompoundTypeDescriptor(info, fieldSemantics);

            lazyArray = io.backend.zarr3.Zarr3LazyArray(...
                obj.Filename, datasetPath, dataDimensions, typeDescriptor, fieldSemantics);
            datasetValue = types.untyped.DataStub(...
                obj.Filename, datasetPath, [], [], lazyArray);
        end

        function datasetValue = readObjectArrayValue(obj, datasetPath)
            % readObjectArrayValue - Decode an array whose elements are
            % JSON-encoded object references (Datatype "object"; see
            % io.internal.zarr3.buildNodeInfo) into a types.untyped.ObjectView
            % object array (matching io.parseReference's shape for HDF5
            % reference datasets, which types.util.checkDtype requires --
            % a cell array of ObjectView is not an accepted dtype). Each
            % element is stored as a zarr "string" containing the same
            % {"source":...,"path":...} JSON convention used for
            % object-reference attributes (io.internal.zarr3.convertAttributes),
            % but is not auto-decoded to a struct by zarr-matlab since the
            % array's own Zarr v3 data_type is plain "string".

            relativePath = io.internal.zarr3.stripLeadingSlash(datasetPath);
            arrayNode = zarr.open(obj.Filename, Path=relativePath);
            rawValues = string(arrayNode.read());

            datasetValue = types.untyped.ObjectView.empty(0, 0);
            for iValue = 1:numel(rawValues)
                datasetValue(iValue) = io.backend.zarr3.Zarr3Reader.decodeObjectReferenceElement(rawValues(iValue));
            end
            datasetValue = reshape(datasetValue, size(rawValues));
        end
    end

    methods (Static, Access = private)
        function objectView = decodeObjectReferenceElement(rawElement)
            decoded = jsondecode(char(rawElement));
            objectView = types.untyped.ObjectView(decoded.path);
        end
    end
end
