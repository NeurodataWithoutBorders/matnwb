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
            attributes = io.backend.zarr2.mw.readAttributes(obj.Filename);
            if isfield(attributes, "nwb_version")
                version = string(attributes.nwb_version);
            else
                error("NWB:Zarr2Reader:MissingSchemaVersion", ...
                    "The Zarr store `%s` does not define `nwb_version` in root .zattrs.", obj.Filename)
            end
        end

        function specLocation = getEmbeddedSpecLocation(obj)
            attributes = io.backend.zarr2.mw.readAttributes(obj.Filename);
            if isfield(attributes, "x_specloc")
                specLocation = string(attributes.x_specloc);
            elseif isfolder(fullfile(obj.Filename, "specifications"))
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
                    "Node `%s` was not found in `%s`.", normalizedPath, obj.Filename)
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
            dataDimensions = obj.getDatasetDims(datasetInfo);
            semanticType = obj.getSemanticType(datasetInfo);
            if isempty(dataDimensions) || prod(dataDimensions) == 1 || semanticType == "object"
                datasetDirectory = obj.resolveDatasetDirectory(datasetPath);
                datasetValue = io.internal.zarr2.readDataset(datasetDirectory, datasetInfo);
            elseif any(dataDimensions == 0)
                datasetValue = [];
            else
                datasetDirectory = obj.resolveDatasetDirectory(datasetPath);
                matlabDataType = io.internal.zarr2.getMatlabDataType(datasetDirectory, datasetInfo);
                lazyArray = io.backend.zarr2.Zarr2LazyArray(...
                    obj.Filename, datasetPath, dataDimensions, matlabDataType);
                datasetValue = types.untyped.DataStub(...
                    obj.Filename, datasetPath, [], [], lazyArray);
            end
        end
    end

    methods (Access = private)
        function ensureMetadataCache(obj)
            if isempty(obj.rootInfoCache)
                [obj.rootInfoCache, obj.nodeInfoMap] = io.internal.zarr2.readConsolidatedInfo(obj.Filename);
            end
        end

        function datasetDirectory = resolveDatasetDirectory(obj, datasetPath)
            relativePath = regexprep(char(datasetPath), '^/', '');
            datasetDirectory = string(fullfile(obj.Filename, relativePath));
        end

        function normalizedPath = normalizeNodePath(~, nodePath)
            normalizedPath = char(nodePath);
            if isempty(normalizedPath)
                normalizedPath = '/';
            elseif normalizedPath(1) ~= '/'
                normalizedPath = ['/' normalizedPath];
            end
        end

        function semanticType = getSemanticType(~, datasetInfo)
            semanticType = "";
            if isfield(datasetInfo, "Datatype") ...
                    && (ischar(datasetInfo.Datatype) || isstring(datasetInfo.Datatype))
                semanticType = lower(string(datasetInfo.Datatype));
            end
        end

        function dataDimensions = getDatasetDims(~, datasetInfo)
            if isfield(datasetInfo, "Dataspace") && isfield(datasetInfo.Dataspace, "Size")
                dataDimensions = double(datasetInfo.Dataspace.Size);
            else
                dataDimensions = [];
            end

            if isempty(dataDimensions) || isscalar(dataDimensions)
                return
            end

            dataDimensions = fliplr(dataDimensions);
        end
    end
end
