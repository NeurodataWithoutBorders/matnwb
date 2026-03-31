classdef Zarr2Reader < io.backend.base.Reader
    % Zarr2Reader - Reader implementation for local consolidated Zarr v2 stores.

    properties (Access = private)
        rootInfoCache = []
        nodeInfoMap = containers.Map('KeyType', 'char', 'ValueType', 'any')
    end

    methods
        function obj = Zarr2Reader(filename)
            obj@io.backend.base.Reader(filename);
        end

        function version = getSchemaVersion(obj)
            attributes = io.backend.zarr2.mw.readAttributes(obj.filename);
            if isfield(attributes, "nwb_version")
                version = string(attributes.nwb_version);
            else
                error("NWB:Zarr2Reader:MissingSchemaVersion", ...
                    "The Zarr store `%s` does not define `nwb_version` in root .zattrs.", obj.filename)
            end
        end

        function specLocation = getEmbeddedSpecLocation(obj)
            attributes = io.backend.zarr2.mw.readAttributes(obj.filename);
            if isfield(attributes, "x_specloc")
                specLocation = string(attributes.x_specloc);
            elseif isfolder(fullfile(obj.filename, "specifications"))
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
            node = obj.rootInfoCache;
        end

        function node = readNodeInfo(obj, nodePath)
            arguments
                obj
                nodePath (1,1) string
            end

            obj.ensureMetadataCache();
            normalizedPath = obj.normalizeNodePath(nodePath);
            if ~isKey(obj.nodeInfoMap, normalizedPath)
                error("NWB:Zarr2Reader:NodeNotFound", ...
                    "Node `%s` was not found in `%s`.", normalizedPath, obj.filename)
            end
            node = obj.nodeInfoMap(normalizedPath);
        end

        function attributeValue = readAttributeValue(~, attributeInfo, ~)
            if ischar(attributeInfo.Datatype) ...
                    && strcmp(attributeInfo.Datatype, "object reference")
                attributeValue = types.untyped.ObjectView(attributeInfo.Value.value.path);
            else
                attributeValue = attributeInfo.Value;
            end
        end

        function datasetValue = readDatasetValue(obj, datasetInfo, datasetPath)
            datasetDirectory = obj.resolveDatasetDirectory(datasetPath);
            rawDatasetInfo = io.backend.zarr2.mw.readInfo(datasetDirectory);
            semanticType = obj.getDatasetSemanticType(datasetInfo);

            if isfield(rawDatasetInfo, "dtype") && strcmp(string(rawDatasetInfo.dtype), "|O")
                datasetValue = io.internal.zarr2.readObjectArray(datasetDirectory);
                datasetValue = obj.postprocessObjectDatasetValue(datasetValue, semanticType);
            else
                datasetValue = io.backend.zarr2.mw.readArray(datasetDirectory);
            end

            datasetValue = obj.normalizeDatasetDimensions(datasetValue);
        end
    end

    methods (Access = private)
        function ensureMetadataCache(obj)
            if isempty(obj.rootInfoCache)
                [obj.rootInfoCache, obj.nodeInfoMap] = io.internal.zarr2.readConsolidatedInfo(obj.filename);
            end
        end

        function datasetDirectory = resolveDatasetDirectory(obj, datasetPath)
            relativePath = regexprep(char(datasetPath), '^/', '');
            datasetDirectory = string(fullfile(obj.filename, relativePath));
        end

        function normalizedPath = normalizeNodePath(~, nodePath)
            normalizedPath = char(nodePath);
            if isempty(normalizedPath)
                normalizedPath = '/';
            elseif normalizedPath(1) ~= '/'
                normalizedPath = ['/' normalizedPath];
            end
        end

        function semanticType = getDatasetSemanticType(~, datasetInfo)
            semanticType = "";
            if isfield(datasetInfo, 'Datatype') ...
                    && (ischar(datasetInfo.Datatype) || isstring(datasetInfo.Datatype))
                semanticType = string(datasetInfo.Datatype);
                return
            end

            attributes = datasetInfo.Attributes;
            if isempty(attributes)
                return
            end

            attributeNames = {attributes.Name};
            zarrTypeMask = strcmp(attributeNames, "zarr_dtype");
            if any(zarrTypeMask)
                semanticType = string(attributes(find(zarrTypeMask, 1, "first")).Value);
            end
        end

        function datasetValue = postprocessObjectDatasetValue(~, datasetValue, semanticType)
            if iscell(datasetValue) && isscalar(datasetValue)
                datasetValue = datasetValue{1};
            end

            if semanticType == "object"
                if isstruct(datasetValue) && isfield(datasetValue, "path")
                    datasetValue = types.untyped.ObjectView(datasetValue.path);
                elseif iscell(datasetValue)
                    datasetValue = cellfun(@(item) types.untyped.ObjectView(item.path), ...
                        datasetValue, 'UniformOutput', false);
                end
            end
        end

        function datasetValue = normalizeDatasetDimensions(~, datasetValue)
            if ischar(datasetValue) || (isstring(datasetValue) && isscalar(datasetValue))
                return
            end

            if iscell(datasetValue) && isscalar(datasetValue)
                datasetValue = datasetValue{1};
                return
            end

            if ndims(datasetValue) <= 1
                return
            elseif ismatrix(datasetValue)
                datasetValue = datasetValue.';
            else
                datasetValue = permute(datasetValue, ndims(datasetValue):-1:1);
            end
        end
    end
end
