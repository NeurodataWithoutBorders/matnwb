function [rootInfo, nodeInfoMap] = readConsolidatedInfo(zarrFile)
% readConsolidatedInfo - Build h5info-like node descriptors from .zmetadata.

    [metadata, keyMap] = readMetadata(zarrFile);
    originalKeyMap = containers.Map(values(keyMap), keys(keyMap));

    rootInfo = initGroupStruct();
    rootInfo.Name = '/';
    rootInfo.Filename = char(zarrFile);

    rootAttributes = getAttributes(metadata, originalKeyMap, '/');
    rootInfo.Attributes = createAttributesStructure(rootAttributes);
    rootInfo.Links = createLinksStructure(rootAttributes);

    [groupPaths, datasetPaths] = processKeys(keyMap);
    groupStructMap = containers.Map('KeyType', 'char', 'ValueType', 'any');

    for iGroup = 1:numel(groupPaths)
        groupPath = groupPaths{iGroup};
        groupStructMap(groupPath) = createGroupStructure(groupPath, metadata, originalKeyMap);
    end

    for iDataset = 1:numel(datasetPaths)
        datasetPath = datasetPaths{iDataset};
        datasetStruct = createDatasetStructure(datasetPath, metadata, originalKeyMap);
        parentPath = getParentPath(datasetPath);

        if strcmp(parentPath, '/')
            rootInfo.Datasets(end+1) = datasetStruct; %#ok<AGROW>
        else
            parentGroup = groupStructMap(parentPath);
            parentGroup.Datasets(end+1) = datasetStruct;
            groupStructMap(parentPath) = parentGroup;
        end
    end

    if ~isempty(groupPaths)
        groupDepths = cellfun(@(path) numel(strfind(path, '/')), groupPaths); %#ok<STRCL1>
        [~, sortOrder] = sort(groupDepths, 'descend');
        groupPaths = groupPaths(sortOrder);
    end

    for iGroup = 1:numel(groupPaths)
        groupPath = groupPaths{iGroup};
        parentPath = getParentPath(groupPath);
        groupStruct = groupStructMap(groupPath);

        if strcmp(parentPath, '/')
            rootInfo.Groups(end+1) = groupStruct; %#ok<AGROW>
        else
            parentGroup = groupStructMap(parentPath);
            parentGroup.Groups(end+1) = groupStruct;
            groupStructMap(parentPath) = parentGroup;
        end
    end

    specificationPath = fullfile(zarrFile, 'specifications');
    if isfolder(specificationPath) ...
            && ~any(strcmp({rootInfo.Groups.Name}, '/specifications'))
        rootInfo.Groups(end+1) = buildFilesystemGroup(zarrFile, '/specifications'); %#ok<AGROW>
    end

    nodeInfoMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
    addGroupNode(rootInfo)

    function addGroupNode(groupInfo)
        nodeInfoMap(groupInfo.Name) = groupInfo;

        for iDataset = 1:numel(groupInfo.Datasets)
            datasetInfo = groupInfo.Datasets(iDataset);
            datasetPath = joinNodePath(groupInfo.Name, datasetInfo.Name);
            nodeInfoMap(datasetPath) = datasetInfo;
        end

        for iChildGroup = 1:numel(groupInfo.Groups)
            addGroupNode(groupInfo.Groups(iChildGroup))
        end
    end
end

function groupInfo = buildFilesystemGroup(zarrFile, groupPath)
    groupInfo = initGroupStruct();
    groupInfo.Name = groupPath;

    groupDirectory = fullfile(zarrFile, stripLeadingSlash(groupPath));
    attributes = [];
    if isfile(fullfile(groupDirectory, '.zattrs'))
        attributes = io.backend.zarr2.mw.readAttributes(groupDirectory);
    end
    groupInfo.Attributes = createAttributesStructure(attributes);
    groupInfo.Links = createLinksStructure(attributes);

    directoryEntries = dir(groupDirectory);
    directoryEntries = directoryEntries([directoryEntries.isdir]);
    directoryEntries = directoryEntries(~startsWith({directoryEntries.name}, '.'));

    for iEntry = 1:numel(directoryEntries)
        entryName = directoryEntries(iEntry).name;
        entryPath = joinNodePath(groupPath, entryName);
        entryDirectory = fullfile(groupDirectory, entryName);

        if isfile(fullfile(entryDirectory, '.zgroup'))
            groupInfo.Groups(end+1) = buildFilesystemGroup(zarrFile, entryPath); %#ok<AGROW>
        elseif isfile(fullfile(entryDirectory, '.zarray'))
            groupInfo.Datasets(end+1) = buildFilesystemDataset(zarrFile, entryPath); %#ok<AGROW>
        end
    end
end

function datasetInfo = buildFilesystemDataset(zarrFile, datasetPath)
    datasetInfo = initDatasetStruct();
    datasetInfo.Name = getLeafName(datasetPath);

    datasetDirectory = fullfile(zarrFile, stripLeadingSlash(datasetPath));
    arrayMeta = io.backend.zarr2.mw.readInfo(datasetDirectory);
    datasetInfo.Datatype = getArrayDatatype(arrayMeta);
    datasetInfo.Dataspace = convertZarrDataspaceToH5(arrayMeta);
    datasetInfo.ChunkSize = getOptionalField(arrayMeta, 'chunks', []);
    datasetInfo.FillValue = getOptionalField(arrayMeta, 'fill_value', []);
    datasetInfo.Filters = convertZarrFiltersToH5(arrayMeta);

    attributes = [];
    if isfile(fullfile(datasetDirectory, '.zattrs'))
        attributes = io.backend.zarr2.mw.readAttributes(datasetDirectory);
        if isfield(attributes, 'zarr_dtype')
            datasetInfo.Datatype = attributes.zarr_dtype;
        end
    end
    datasetInfo.Attributes = createAttributesStructure(attributes);
end

function [metadata, keyMap] = readMetadata(zarrFile)
    metadataFile = fullfile(zarrFile, '.zmetadata');
    if ~isfile(metadataFile)
        error("NWB:Zarr2:MissingConsolidatedMetadata", ...
            "No .zmetadata file found in `%s`.", zarrFile)
    end

    zmetadata = jsondecode(fileread(metadataFile));
    if ~isfield(zmetadata, 'metadata')
        error("NWB:Zarr2:InvalidConsolidatedMetadata", ...
            "The .zmetadata file in `%s` does not contain a `metadata` field.", zarrFile)
    end

    metadata = zmetadata.metadata;
    originalKeys = extractMetadataKeys(metadataFile);
    fieldNames = fieldnames(metadata);
    assert(numel(originalKeys) == numel(fieldNames), ...
        'NWB:Zarr2:MetadataKeyMismatch', ...
        'Unable to align decoded .zmetadata fields with original keys.')

    keyMap = containers.Map(fieldNames, originalKeys);
end

function groupStruct = createGroupStructure(groupPath, metadata, originalKeyMap)
    groupStruct = initGroupStruct();
    groupStruct.Name = groupPath;

    attributes = getAttributes(metadata, originalKeyMap, groupPath);
    groupStruct.Attributes = createAttributesStructure(attributes);
    groupStruct.Links = createLinksStructure(attributes);
end

function datasetStruct = createDatasetStructure(datasetPath, metadata, originalKeyMap)
    datasetStruct = initDatasetStruct();
    datasetStruct.Name = getLeafName(datasetPath);

    arrayKey = sprintf('%s/.zarray', stripLeadingSlash(datasetPath));
    if ~isKey(originalKeyMap, arrayKey)
        error("NWB:Zarr2:DatasetMetadataMissing", ...
            "No .zarray metadata found for dataset `%s`.", datasetPath)
    end

    arrayMeta = metadata.(originalKeyMap(arrayKey));
    datasetStruct.Datatype = getArrayDatatype(arrayMeta);
    datasetStruct.Dataspace = convertZarrDataspaceToH5(arrayMeta);
    datasetStruct.ChunkSize = getOptionalField(arrayMeta, 'chunks', []);
    datasetStruct.FillValue = getOptionalField(arrayMeta, 'fill_value', []);
    datasetStruct.Filters = convertZarrFiltersToH5(arrayMeta);

    attributes = getAttributes(metadata, originalKeyMap, datasetPath);
    if ~isempty(attributes) && isfield(attributes, 'zarr_dtype')
        datasetStruct.Datatype = attributes.zarr_dtype;
    end
    datasetStruct.Attributes = createAttributesStructure(attributes);
end

function attributes = getAttributes(metadata, originalKeyMap, elementPath)
    if strcmp(elementPath, '/')
        attributeKey = '.zattrs';
    else
        attributeKey = sprintf('%s/.zattrs', stripLeadingSlash(elementPath));
    end

    if ~isKey(originalKeyMap, attributeKey)
        attributes = [];
        return
    end

    attributes = metadata.(originalKeyMap(attributeKey));
end

function [groupPaths, datasetPaths] = processKeys(keyMap)
    originalKeys = values(keyMap);
    groupPaths = {};
    datasetPaths = {};

    for iKey = 1:numel(originalKeys)
        originalKey = originalKeys{iKey};
        if strcmp(originalKey, '.zgroup')
            continue
        elseif endsWith(originalKey, '/.zgroup')
            groupPaths{end+1} = ['/' erase(originalKey, '/.zgroup')]; %#ok<AGROW>
        elseif endsWith(originalKey, '/.zarray')
            datasetPaths{end+1} = ['/' erase(originalKey, '/.zarray')]; %#ok<AGROW>
        end
    end

    groupPaths = unique(groupPaths);
    datasetPaths = unique(datasetPaths);
end

function attributes = createAttributesStructure(zarrAttributes)
    if isempty(zarrAttributes)
        attributes = emptyAttributeStruct();
        return
    end

    rawAttributeNames = fieldnames(zarrAttributes);
    specialKeyMap = getSpecialKeysMap();
    reservedNames = ["zarr_link", "zarr_dtype", "_ARRAY_DIMENSIONS"];
    attributes = emptyAttributeStruct();

    for iAttribute = 1:numel(rawAttributeNames)
        rawName = rawAttributeNames{iAttribute};
        if isKey(specialKeyMap, rawName)
            attributeName = specialKeyMap(rawName);
        else
            attributeName = rawName;
        end

        if any(strcmp(attributeName, reservedNames))
            continue
        end

        attribute = initAttributeStruct();
        attribute.Name = attributeName;
        attribute.Value = zarrAttributes.(rawName);
        if isstruct(attribute.Value) ...
                && isfield(attribute.Value, 'zarr_dtype') ...
                && strcmp(attribute.Value.zarr_dtype, 'object')
            attribute.Datatype = 'object reference';
        else
            attribute.Datatype = [];
        end
        attribute.Dataspace = [];
        attributes(end+1) = attribute; %#ok<AGROW>
    end
end

function links = createLinksStructure(zarrAttributes)
    links = emptyLinkStruct();
    if isempty(zarrAttributes) || ~isfield(zarrAttributes, 'zarr_link')
        return
    end

    zarrLinks = zarrAttributes.zarr_link;
    if ~iscell(zarrLinks)
        zarrLinks = num2cell(zarrLinks);
    end

    for iLink = 1:numel(zarrLinks)
        zarrLink = zarrLinks{iLink};
        link = initLinkStruct();
        link.Name = zarrLink.name;
        if strcmp(zarrLink.source, '.')
            link.Type = 'soft link';
            link.Value = {zarrLink.path};
        else
            link.Type = 'external link';
            link.Value = {zarrLink.source, zarrLink.path};
        end
        links(end+1) = link; %#ok<AGROW>
    end
end

function dataspace = convertZarrDataspaceToH5(arrayMeta)
    dataspace = struct('Size', [], 'MaxSize', [], 'Type', 'unknown');
    if ~isfield(arrayMeta, 'shape')
        return
    end

    shape = double(arrayMeta.shape(:)');
    dataspace.Size = shape;
    dataspace.MaxSize = shape;
    dataspace.Type = 'simple';
end

function filters = convertZarrFiltersToH5(arrayMeta)
    filters = struct('Name', {}, 'Parameters', {});

    if isfield(arrayMeta, 'compressor') && ~isempty(arrayMeta.compressor)
        filter = struct();
        filter.Name = getOptionalField(arrayMeta.compressor, 'id', 'unknown');
        filter.Parameters = arrayMeta.compressor;
        filters(end+1) = filter; %#ok<AGROW>
    end

    if isfield(arrayMeta, 'filters') && ~isempty(arrayMeta.filters)
        zarrFilters = arrayMeta.filters;
        if ~iscell(zarrFilters)
            zarrFilters = num2cell(zarrFilters);
        end

        for iFilter = 1:numel(zarrFilters)
            filter = struct();
            filter.Name = getOptionalField(zarrFilters{iFilter}, 'id', 'unknown');
            filter.Parameters = zarrFilters{iFilter};
            filters(end+1) = filter; %#ok<AGROW>
        end
    end
end

function keys = extractMetadataKeys(metadataFile)
    metadataText = fileread(metadataFile);
    metadataStart = regexp(metadataText, '"metadata"\s*:\s*\{', 'end', 'once');
    if isempty(metadataStart)
        error("NWB:Zarr2:InvalidConsolidatedMetadata", ...
            "The .zmetadata file `%s` does not contain a `metadata` object.", metadataFile)
    end

    level = 1;
    index = metadataStart + 1;
    while level > 0 && index <= length(metadataText)
        currentCharacter = metadataText(index);
        if currentCharacter == "{"
            level = level + 1;
        elseif currentCharacter == "}"
            level = level - 1;
        end
        index = index + 1;
    end

    metadataBlock = metadataText(metadataStart+1:index-2);
    keys = {};
    [startIndices, ~, ~, matches] = regexp(metadataBlock, '"([^"]+)"\s*:', ...
        'start', 'end', 'match', 'tokens');

    for iMatch = 1:numel(startIndices)
        prefix = metadataBlock(1:startIndices(iMatch));
        nestingLevel = sum(prefix == '{') - sum(prefix == '}');
        if nestingLevel == 0
            keys{end+1} = matches{iMatch}{1}; %#ok<AGROW>
        end
    end
end

function specialKeyMap = getSpecialKeysMap()
    specialKeyMap = containers.Map();
    specialKeyMap('x_specloc') = '.specloc';
    specialKeyMap('x_ARRAY_DIMENSIONS') = '_ARRAY_DIMENSIONS';
end

function path = getParentPath(nodePath)
    slashIndices = strfind(nodePath, '/');
    if numel(slashIndices) <= 1
        path = '/';
    else
        path = nodePath(1:slashIndices(end)-1);
    end
end

function leafName = getLeafName(nodePath)
    pathParts = split(string(nodePath), "/");
    leafName = char(pathParts(end));
end

function joinedPath = joinNodePath(parentPath, childName)
    if strcmp(parentPath, '/')
        joinedPath = ['/' childName];
    else
        joinedPath = [parentPath '/' childName];
    end
end

function value = getOptionalField(structure, fieldName, defaultValue)
    if isfield(structure, fieldName)
        value = structure.(fieldName);
    else
        value = defaultValue;
    end
end

function strippedPath = stripLeadingSlash(nodePath)
    strippedPath = regexprep(char(nodePath), '^/', '');
end

function datatype = getArrayDatatype(arrayMeta)
    if isfield(arrayMeta, 'dtype')
        datatype = arrayMeta.dtype;
    else
        datatype = [];
    end
end

function groupStruct = initGroupStruct()
    groupStruct = struct('Name', '', 'Filename', '', ...
        'Groups', emptyGroupStruct(), ...
        'Datasets', emptyDatasetStruct(), ...
        'Links', emptyLinkStruct(), ...
        'Attributes', emptyAttributeStruct());
end

function datasetStruct = initDatasetStruct()
    datasetStruct = struct('Name', '', 'Datatype', [], ...
        'Dataspace', struct('Size', [], 'MaxSize', [], 'Type', 'unknown'), ...
        'ChunkSize', [], 'FillValue', [], ...
        'Filters', struct('Name', {}, 'Parameters', {}), ...
        'Attributes', emptyAttributeStruct());
end

function attributeStruct = initAttributeStruct()
    attributeStruct = struct('Name', '', 'Datatype', [], 'Dataspace', [], 'Value', []);
end

function linkStruct = initLinkStruct()
    linkStruct = struct('Name', '', 'Type', '', 'Value', []);
end

function groupStruct = emptyGroupStruct()
    groupStruct = struct('Name', {}, 'Filename', {}, 'Groups', {}, 'Datasets', {}, 'Links', {}, 'Attributes', {});
end

function datasetStruct = emptyDatasetStruct()
    datasetStruct = struct('Name', {}, 'Datatype', {}, 'Dataspace', {}, 'ChunkSize', {}, 'FillValue', {}, 'Filters', {}, 'Attributes', {});
end

function attributeStruct = emptyAttributeStruct()
    attributeStruct = struct('Name', {}, 'Datatype', {}, 'Dataspace', {}, 'Value', {});
end

function linkStruct = emptyLinkStruct()
    linkStruct = struct('Name', {}, 'Type', {}, 'Value', {});
end
