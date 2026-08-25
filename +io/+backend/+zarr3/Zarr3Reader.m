classdef Zarr3Reader < io.backend.base.Reader
% Zarr3Reader - Reader implementation for local Zarr v3 stores.
%
% This reader is backed by the zarr-matlab package
% (https://github.com/catalystneuro/zarr-matlab), which must be on the
% MATLAB path, and reads Zarr v3 stores natively in MATLAB (no Python
% dependency).
%
% The hdmf-zarr storage conventions that layer HDF5's links and object
% references on top of Zarr (https://hdmf-zarr.readthedocs.io/en/latest/storage.html)
% are handled by the hdmf-zarr-matlab package
% (https://github.com/catalystneuro/hdmf-zarr-matlab), which must also
% be on the MATLAB path:
% - group links are "zarr_link" attribute records (hdmf.zarr.Link),
%     surfaced as h5info-style Links by io.internal.zarr3.convertAttributes;
% - an object reference is a {source, path, object_id, ...} record
%     (hdmf.zarr.Reference), stored as {zarr_dtype:"object", value:<record>}
%     in an attribute, or as the JSON-string elements of a dataset
%     tagged zarr_dtype:"object" (hdmf.zarr.isReferenceArray), e.g. a
%     DynamicTable column of ElectrodeGroup references. Both decode to
%     types.untyped.ObjectView via io.internal.zarr3.decodeObjectReferences;
% - the root ".specloc" attribute names the cached specifications
%     group (io.internal.zarr3.getSpecLocAttributeName).
%
% A compound (struct/table) dataset -- a Zarr v3 "structured" data_type,
% e.g. PlaneSegmentation's pixel_mask/voxel_mask, or
% TimeSeriesReferenceVectorData's response/stimulus columns -- is backed
% by io.backend.zarr3.Zarr3LazyArray; a field tagged "object" via the
% array's "zarr_dtype" attribute (see
% io.internal.zarr3.getObjectReferenceFields) holds the same JSON
% reference records and is decoded the same way. Requires zarr-matlab
% to support the Zarr v3 "structured" and "fixed_length_utf32" data
% types, which are unstable, unspecified zarr-python extensions -- see
% zarr.internal.dtype_info in zarr-matlab.

    properties (Access = private)
        % RootGroup - zarr.Group at the root of the store. Entry point for
        % walking the hierarchy, and the source of the root attributes that
        % carry nwb_version and the cached-specification location.
        RootGroup = []

        % RootInfoCache - h5info-style struct describing the root node,
        % returned by readRootInfo.
        RootInfoCache = []

        % NodeInfoMap - containers.Map from absolute node path (char, leading
        % '/') to that node's h5info-style struct, backing readNodeInfo.
        %
        % A containers.Map is a handle, so it must not be created as a
        % property default: that would share one map across every
        % Zarr3Reader instance. It is built in ensureMetadataCache instead,
        % which populates all four of these properties in one pass so the
        % store is walked only once per reader.
        NodeInfoMap = []
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
            % hdmf-zarr records the cached-specifications group in the root
            % ".specloc" attribute; fall back to the conventional group name
            % when a writer omitted it.
            specLocation = "";
            attributes = obj.RootGroup.attrs;
            specLocAttribute = io.internal.zarr3.getSpecLocAttributeName();
            if isfield(attributes, specLocAttribute)
                specLocation = string(attributes.(specLocAttribute));
            end
            if specLocation == "" && obj.RootGroup.isKey("specifications")
                specLocation = "/specifications";
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
                attributeValue = io.internal.zarr3.decodeObjectReferences(attributeInfo.Value);
            else
                attributeValue = attributeInfo.Value;
            end
        end

        function tf = isReferenceDataset(~, datasetInfo)
        % isReferenceDataset - Whether a dataset holds object references.
        %
        % Zarr v3 has no native reference type. hdmf-zarr marks such a
        % dataset with a zarr_dtype of "object", which
        % io.internal.zarr3.buildNodeInfo surfaces as the node's Datatype
        % (see hdmf.zarr.isReferenceArray).
            tf = strcmp(datasetInfo.Datatype, "object");
        end

        function datasetValue = readDatasetValue(obj, datasetInfo, datasetPath)
            dataDimensions = obj.getDatasetDims(datasetInfo);
            isObjectReferenceArray = obj.isReferenceDataset(datasetInfo);
            isStructuredArray = strcmp(datasetInfo.Datatype, "structured");
            % A true rank-0 array, or one explicitly marked "scalar" by
            % hdmf-zarr's zarr_dtype hint (see
            % io.internal.zarr3.buildNodeInfo), is read eagerly. Dataspace.Size == 1 alone is NOT a reliable scalar
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
        % readStructuredValue - Wrap a compound array in a DataStub.
        %
        % The DataStub is backed by io.backend.zarr3.Zarr3LazyArray, and its
        % dataType is a compound type descriptor struct (field name -> MATLAB
        % class name, or 'types.untyped.ObjectView' for a field tagged as a
        % reference via the array's own "zarr_dtype" attribute; see
        % io.internal.zarr3.getCompoundTypeDescriptor) rather than a plain
        % class name, matching what types.util.checkDtype and
        % types.untyped.DataStub.isCompoundType expect. This alone is enough
        % for schema validation to succeed without loading any data (see
        % types.util.checkDtype>checkDtypeForCompoundDataset's DataStub fast
        % path).

            relativePath = io.internal.zarr3.stripLeadingSlash(datasetPath);
            arrayNode = zarr.open(obj.Filename, Path=relativePath);
            info = zarr.internal.dtype_info(arrayNode.meta.dataType, arrayNode.meta.dataTypeConfig);
            objectReferenceFields = io.internal.zarr3.getObjectReferenceFields(arrayNode.attrs);
            typeDescriptor = io.internal.zarr3.getCompoundTypeDescriptor(info, objectReferenceFields);

            lazyArray = io.backend.zarr3.Zarr3LazyArray(...
                obj.Filename, datasetPath, dataDimensions, typeDescriptor, objectReferenceFields);
            datasetValue = types.untyped.DataStub(...
                obj.Filename, datasetPath, [], [], lazyArray);
        end

        function datasetValue = readObjectArrayValue(obj, datasetPath)
        % readObjectArrayValue - Decode a dataset of object references.
        %
        % Decodes a dataset whose Datatype is "object" (see
        % io.internal.zarr3.buildNodeInfo) into a types.untyped.ObjectView
        % array. Each element is a zarr "string" holding a JSON reference
        % record (hdmf.zarr.Reference); zarr-matlab does not decode these
        % itself since the array's own Zarr v3 data_type is plain "string".

            relativePath = io.internal.zarr3.stripLeadingSlash(datasetPath);
            arrayNode = zarr.open(obj.Filename, Path=relativePath);
            rawValues = string(arrayNode.read());
            datasetValue = io.internal.zarr3.decodeObjectReferences(rawValues);
        end
    end
end
