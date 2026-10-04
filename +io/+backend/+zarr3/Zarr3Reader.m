classdef Zarr3Reader < io.backend.base.Reader
% Zarr3Reader - Reader implementation for Zarr v3 stores.
%
% The store is a local directory or an http(s) URL (see
% io.internal.zarr3.openNode).
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
% - group links are records in the "_LINKS" attribute (hdmf.zarr.Link),
%     surfaced as h5info-style Links by io.internal.zarr3.convertAttributes;
% - an object reference is a {source, path} record (hdmf.zarr.Reference),
%     stored as {"_REFERENCE": <record>} in an attribute, or as the
%     target-path elements of a dataset tagged _DTYPE:"object_reference"
%     (hdmf.zarr.isReferenceArray), e.g. a DynamicTable column of
%     ElectrodeGroup references. Both decode to types.untyped.ObjectView
%     via io.internal.zarr3.decodeObjectReferences;
% - the root ".specloc" attribute names the cached specifications
%     group (io.internal.zarr3.getSpecLocAttributeName).
% Stores written before hdmf-zarr 0.14 use the older forms of the same
% conventions (zarr_link, zarr_dtype, JSON reference records), which are
% read as well.
%
% A compound (struct/table) dataset -- a Zarr v3 "struct" data_type (named
% "structured" by zarr-python before 3.4), e.g. PlaneSegmentation's
% pixel_mask/voxel_mask, or TimeSeriesReferenceVectorData's
% response/stimulus columns -- is backed by
% io.backend.zarr3.Zarr3LazyArray; a field listed in the array's
% "_REFERENCE_FIELDS" attribute (see
% io.internal.zarr3.getObjectReferenceFields) holds references in the same
% form as a reference dataset and is decoded the same way.

    properties (Constant, Access = private)
        % MaxPrefetchElements - Largest single-chunk array whose chunk is
        % fetched up front when the store is read over HTTP (see
        % smallArrayChunkKeys).
        MaxPrefetchElements = 1e5
    end

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
            [hasVersion, version] = io.internal.zarr3.getAttribute(...
                obj.RootGroup.attrs, "nwb_version");
            if hasVersion
                version = string(version);
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
            [hasSpecLoc, specLocValue] = io.internal.zarr3.getAttribute(...
                obj.RootGroup.attrs, io.internal.zarr3.getSpecLocAttributeName());
            if hasSpecLoc
                specLocation = string(specLocValue);
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

        function base = getExternalLinkBase(obj)
        % getExternalLinkBase - Base for resolving relative link targets.
        %
        % hdmf-zarr computes a relative external-link source against the
        % store path itself, not the store's parent directory: a store is a
        % directory, so the same relpath(target, file) formula HDF5 tooling
        % applies yields one extra ".." (see os.path.relpath in hdmf-zarr's
        % backend.py, and the discussion on issue #865). Returned as an
        % absolute path so a link dereferenced after the working directory
        % has changed still resolves correctly. A store read over HTTP is
        % its own base: a relative source resolves against its URL.
            if matnwb.common.isUrl(obj.Filename)
                base = strip(obj.Filename, "right", "/");
                return
            end
            [isResolved, fileInfo] = fileattrib(char(obj.Filename));
            assert(isResolved, ...
                'NWB:Backend:Reader:FileNotFound', ...
                'Could not resolve the location of `%s`.', obj.Filename);
            base = string(fileInfo.Name);
        end

        function tf = isReferenceDataset(~, datasetInfo)
        % isReferenceDataset - Whether a dataset holds object references.
        %
        % Zarr v3 has no native reference type. hdmf-zarr marks such a
        % dataset with a _DTYPE of "object_reference", which
        % io.internal.zarr3.buildNodeInfo surfaces as the node's Datatype
        % (see hdmf.zarr.isReferenceArray).
            tf = strcmp(datasetInfo.Datatype, "object");
        end

        function datasetValue = readDatasetValue(obj, datasetInfo, datasetPath)
            dataDimensions = obj.getDatasetDims(datasetInfo);
            isObjectReferenceArray = obj.isReferenceDataset(datasetInfo);
            % zarr-python 3.4 names the structured data type "struct";
            % earlier versions wrote "structured".
            isStructuredArray = any(strcmp(datasetInfo.Datatype, ["struct", "structured"]));
            % A true rank-0 array, or one explicitly marked "scalar" by the
            % zarr_dtype hint of stores written before hdmf-zarr 0.14 (see
            % io.internal.zarr3.buildNodeInfo), is read eagerly.
            % Dataspace.Size == 1 alone is NOT a reliable scalar signal: it
            % is also the shape of a one-row VectorData column (e.g. a
            % DynamicTable with a single row) -- collapsing that to a bare
            % value would silently corrupt it (a char column's character
            % count would be misread as its row count downstream).
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
                    obj.Filename, datasetPath, dataDimensions, matlabDataType, ...
                    ArrayNode=obj.openArray(datasetPath));
                datasetValue = types.untyped.DataStub(...
                    obj.Filename, datasetPath, [], [], lazyArray);
            end
        end
    end

    methods (Access = private)
        function ensureMetadataCache(obj)
            if isempty(obj.RootGroup)
                io.backend.zarr3.internal.ensureAvailable()
                store = io.internal.zarr3.createStore(obj.Filename);
                if matnwb.common.isUrl(obj.Filename)
                    store = io.backend.zarr3.internal.PrefetchStore(store);
                end
                obj.RootGroup = zarr.open(store);
                [obj.RootInfoCache, obj.NodeInfoMap] = io.internal.zarr3.buildNodeInfo(obj.RootGroup);
                obj.RootInfoCache.Filename = char(obj.Filename);
                if isa(store, "io.backend.zarr3.internal.PrefetchStore")
                    store.prefetch(obj.smallArrayChunkKeys());
                end
            end
        end

        function chunkKeys = smallArrayChunkKeys(obj)
        % smallArrayChunkKeys - Store keys of the chunks of every small array.
        %
        % nwbRead reads most small arrays while it parses a store: scalars,
        % the cached specifications, id columns and other short columns,
        % reference datasets. Over HTTP each read is a round trip, so their
        % chunks are fetched together up front. An array counts as small
        % when it is a single chunk of at most MaxPrefetchElements elements;
        % larger arrays are read on demand.
            chunkKeys = strings(0, 1);
            nodePaths = string(keys(obj.NodeInfoMap));
            nodeInfos = values(obj.NodeInfoMap);
            for iNode = 1:numel(nodePaths)
                nodeInfo = nodeInfos{iNode};
                if ~isfield(nodeInfo, "Dataspace")
                    continue  % a group
                end
                shape = double(nodeInfo.Dataspace.Size);
                chunkShape = double(nodeInfo.ChunkSize);
                isSingleChunk = all(shape <= chunkShape);
                if prod(shape) > obj.MaxPrefetchElements || ~isSingleChunk || any(shape == 0)
                    continue
                end
                arrayNode = obj.openArray(nodePaths(iNode));
                chunkKeys(end+1, 1) = io.internal.zarr3.stripLeadingSlash(nodePaths(iNode)) ...
                    + "/" + arrayNode.meta.chunkKey(zeros(1, numel(shape))); %#ok<AGROW>
            end
        end

        function arrayNode = openArray(obj, datasetPath)
        % openArray - Open a dataset through the root group.
        %
        % The root group holds the store's consolidated metadata, so the
        % array is opened without fetching its zarr.json again, which over
        % HTTP saves a request per dataset. zarr.Group.item reads the store
        % only for a node the consolidated metadata does not describe.
            obj.ensureMetadataCache();
            arrayNode = obj.RootGroup.item(io.internal.zarr3.stripLeadingSlash(datasetPath));
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
            datasetValue = obj.openArray(datasetPath).read();

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
        % class name, or 'types.untyped.ObjectView' for a field the array's
        % attributes declare a reference; see
        % io.internal.zarr3.getCompoundTypeDescriptor) rather than a plain
        % class name, matching what types.util.checkDtype and
        % types.untyped.DataStub.isCompoundType expect. This alone is enough
        % for schema validation to succeed without loading any data (see
        % types.util.checkDtype>checkDtypeForCompoundDataset's DataStub fast
        % path).

            arrayNode = obj.openArray(datasetPath);
            info = zarr.internal.dtype_info(arrayNode.meta.dataType, arrayNode.meta.dataTypeConfig);
            objectReferenceFields = io.internal.zarr3.getObjectReferenceFields(arrayNode.attrs);
            typeDescriptor = io.internal.zarr3.getCompoundTypeDescriptor(info, objectReferenceFields);

            lazyArray = io.backend.zarr3.Zarr3LazyArray(...
                obj.Filename, datasetPath, dataDimensions, typeDescriptor, objectReferenceFields, ...
                ArrayNode=arrayNode);
            datasetValue = types.untyped.DataStub(...
                obj.Filename, datasetPath, [], [], lazyArray);
        end

        function datasetValue = readObjectArrayValue(obj, datasetPath)
        % readObjectArrayValue - Decode a dataset of object references.
        %
        % Decodes a dataset whose Datatype is "object" (see
        % io.internal.zarr3.buildNodeInfo) into a types.untyped.ObjectView
        % array. Each element is a zarr "string" holding a reference in a
        % form hdmf.zarr.Reference decodes; zarr-matlab does not decode
        % these itself since the array's own Zarr v3 data_type is plain
        % "string".

            rawValues = string(obj.openArray(datasetPath).read());
            datasetValue = io.internal.zarr3.decodeObjectReferences(rawValues);
        end
    end
end
