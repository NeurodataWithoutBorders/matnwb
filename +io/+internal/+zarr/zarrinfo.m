function info = zarrinfo(filepath)
%ZARRINFO Read Zarr info from consolidated metadata
%   INFO = ZARRINFO(FILEPATH) reads consolidated metadata from a .zmetadata file
%   and returns a hierarchical structure of nested primitive types from HDMF.
%
%   The returned structure contains:
%   - Name: The full path name
%   - Groups: Array of subgroup structures
%   - Datasets: Array of dataset/array structures  
%   - Attributes: Array of attribute structures
%   - Links:  Array of link structures
%   - Filename: The path to the Zarr group
%
%   See also:
%       initGroupStructure
%       initLinkStructure
%       initDatasetStructure
%       initAttributeStructure
%
%   Example:
%       % Read consolidated Zarr info
%       info = zarrinfo('mydata.zarr')
%
%       % Access nested structure like h5info
%       acquisitionGroup = info.Groups(1);  % First group
%       firstDataset = acquisitionGroup.Datasets(1);  % First dataset

    arguments
        filepath {mustBeTextScalar, mustBeNonzeroLengthText}
    end
    
    zmetadata = readMetadata(filepath);

    % Need to extract the primary keys from the file, as MATLAB's json
    % decoder converts all keys to valid struct fieldnames 
    primaryKeys = io.internal.zarr.extractZarrMetadataKeys(filepath);
    
    % Create a mapping between field names and keys.
    fieldNames = fieldnames(zmetadata.metadata);
    assert(numel(primaryKeys) == numel(fieldNames), ...
        'Expected number of primary keys and number of metadata fields to be the same.')

    keyMap = containers.Map(fieldNames, primaryKeys);
    
    % Build hierarchical structure
    info = buildHierarchicalHDMFStructure(filepath, zmetadata.metadata, keyMap);
end
    
function info = buildHierarchicalHDMFStructure(filepath, metadata, keyMap)
%BUILDHIERARCHICALSTRUCTURE Convert flat metadata to hierarchical structure

    % Initialize root structure
    info = struct();
    info.Filename = filepath;
    info.Name = '/';
    info.Groups = [];
    info.Datasets = [];
    info.Links = [];
    info.Attributes = [];
    
    % Create a reverse map to map fieldnames -> zarr keys
    reverseMap = containers.Map(keyMap.values, keyMap.keys);
    
    % Get root attributes
    if isfield(metadata, 'x_zattrs')
        rootAttrs = metadata.('x_zattrs');
        info.Attributes = createAttributesStructure(rootAttrs);
    end

    [groupPaths, datasetPaths] = processKeys(metadata, keyMap);
    
    % Build group hierarchy
    groupStructs = containers.Map();
    
    % Create all groups first
    for i = 1:length(groupPaths)
        groupPath = groupPaths{i};
        groupStruct = createGroupStructure(groupPath, metadata, reverseMap);
        groupStructs(groupPath) = groupStruct;
    end
    
    % Add datasets to appropriate groups
    for i = 1:length(datasetPaths)
        datasetPath = datasetPaths{i};
        datasetStruct = createDatasetStructure(datasetPath, metadata, reverseMap);
        
        % Find parent group
        parentPath = getParentPath(datasetPath);
        
        if strcmp(parentPath, '') || strcmp(parentPath, '/')
            % Root level dataset
            if isempty(info.Datasets)
                info.Datasets = datasetStruct;
            else
                info.Datasets(end+1) = datasetStruct;
            end
        else
            % Add to parent group
            if isKey(groupStructs, parentPath)
                parentGroup = groupStructs(parentPath);
                parentGroup.Datasets(end+1) = datasetStruct;
                groupStructs(parentPath) = parentGroup;
            end
        end
    end
    
    % Sort paths so that the deepest groups are handled first when building
    % the hierarchical/nested structure
    groupLevels = cellfun(@(c) numel(split(c, '/')), groupPaths);
    [~, sortOrder] = sort(groupLevels, 'descend');
    groupPaths = groupPaths(sortOrder);
    
    % Build nested group structure
    rootGroups = initGroupStruct;
    for i = 1:length(groupPaths)
        groupPath = groupPaths{i};
        parentPath = getParentPath(groupPath);
        
        if strcmp(parentPath, '') || strcmp(parentPath, '/')
            % Root level group
            rootGroups(end+1) = groupStructs(groupPath); %#ok<AGROW>
        else
            % Nested group - add to parent
            if isKey(groupStructs, parentPath)
                parentGroup = groupStructs(parentPath);
                childGroup = groupStructs(groupPath);
                parentGroup.Groups(end+1) = childGroup;
                groupStructs(parentPath) = parentGroup;
            end
        end
    end
    info.Groups = rootGroups;
end

function path = extractPathFromKey(key, type)
%EXTRACTPATHFROMKEY Extract the path from a metadata key
    
    if type == "group"
        if endsWith(key, '/.zgroup')
            path = key(1:end-8); % Remove '/.zgroup'
        elseif endsWith(key, 'x_zgroup')
            path = key(1:end-8); % Remove 'x_zgroup'
            path = strrep(path, '_', '/'); % Convert underscores to slashes
        elseif endsWith(key, '_zgroup')
            path = key(1:end-7); % Remove '_zgroup'
            path = strrep(path, '_', '/'); % Convert underscores to slashes
        else
            path = '';
        end
    elseif type == "array"
        if endsWith(key, '/.zarray')
            path = key(1:end-8); % Remove '/.zarray'
        elseif endsWith(key, '_zarray')
            path = key(1:end-7); % Remove '_zarray'
            path = strrep(path, '_', '/'); % Convert underscores to slashes
        else
            path = '';
        end
    else
        path = '';
    end
end

function parentPath = getParentPath(fullPath)
%GETPARENTPATH Get the parent directory path
    
    parts = split(fullPath, '/');
    if length(parts) <= 1
        parentPath = '';
    else
        parentPath = strjoin(parts(1:end-1), '/');
    end
end

function groupStruct = createGroupStructure(groupPath, metadata, keyMap)
    %CREATEGROUPSTRUCTURE Create a group structure from metadata
    
    groupStruct = initGroupStruct();
    groupStruct(1).Name = groupPath; % ['/' groupPath]; TODO: Should it be prepended with /
    
    % Look for group attributes
    zAttributes = getAttributes(metadata, groupPath, keyMap);

    if ~isempty(zAttributes)
        groupStruct.Attributes = createAttributesStructure(zAttributes);
        groupStruct.Links = createLinksStructure(zAttributes);
    end
end

function datasetStruct = createDatasetStructure(datasetPath, metadata, keyMap)
%CREATEDATASETSTRUCTURE Create a dataset structure from metadata
    
    % Get dataset name (last part of path)
    parts = split(datasetPath, '/');
    datasetName = parts{end};
    
    datasetStruct = struct();
    datasetStruct.Name = datasetName;
    datasetStruct.Datatype = initDatatypeStruct();
    datasetStruct.Dataspace = initDataspaceStruct(); % Todo: Not needed.
    datasetStruct.ChunkSize = [];
    datasetStruct.FillValue = [];
    datasetStruct.Filters = struct('Name', {}, 'Parameters', {}); % Todo: Not needed.
    datasetStruct.Attributes = initAttributeStruct();
    
    % Look for array metadata
    arrayKey = [datasetPath '/.zarray'];
    
    if isKey(keyMap, arrayKey)
        fieldName = keyMap(arrayKey);
    else
        error('todo')
    end

    arrayMeta = [];
    if isfield(metadata, fieldName)
        arrayMeta = metadata.(fieldName);
    end
    
    if ~isempty(arrayMeta)
        % Convert Zarr array metadata to hdmf format (Todo)
        datasetStruct.Datatype = []; % Todo: convertZarrDatatypeToH5(arrayMeta);
        datasetStruct.Dataspace = convertZarrDataspaceToH5(arrayMeta);
        datasetStruct.ChunkSize = arrayMeta.chunks;
        datasetStruct.FillValue = arrayMeta.fill_value;
        datasetStruct.Filters = convertZarrFiltersToH5(arrayMeta);
    end
    
    % Look for dataset attributes
    zAttributes = getAttributes(metadata, datasetPath, keyMap);

    if isfield(zAttributes, 'zarr_dtype')
        datasetStruct.Datatype = zAttributes.zarr_dtype;
    end
    
    if ~isempty(zAttributes)
        datasetStruct.Attributes = createAttributesStructure(zAttributes);
    end
end

function nwbAttrs = createAttributesStructure(zarrAttrs)
%CONVERTATTRIBUTESTOH5FORMAT Convert Zarr attributes to h5info format

    if isempty(zarrAttrs)
        nwbAttrs = [];
        return;
    end
    
    attrNames = fieldnames(zarrAttrs);
    nwbAttrs = initAttributeStruct();

    keyMap = io.internal.zarr.getSpecialKeysMap();
    reservedKeys = ["zarr_link", "zarr_dtype", "_ARRAY_DIMENSIONS"];

    for i = 1:length(attrNames)
        attr = struct();

        if isKey(keyMap, attrNames{i})
            attr.Name = keyMap(attrNames{i});
        else
            attr.Name = attrNames{i};
        end


        % Skip reserved hdmf-zarr keys
        if any(strcmp(attr.Name, reservedKeys))
            continue
        end

        attr.Value = zarrAttrs.(attrNames{i});
        attr.Datatype = [];
        attr.Dataspace = [];

        if isfield(zarrAttrs.(attrNames{i}), 'zarr_dtype')
            if strcmp( zarrAttrs.(attrNames{i}).zarr_dtype, 'object' )
                attr.Datatype = 'object reference';
            else
                keyboard
            end
        end
        
        nwbAttrs(end+1) = attr; %#ok<AGROW>
    end

end

function hdmfLinks = createLinksStructure(zAttributes)
    hdmfLinks = [];
    if isfield(zAttributes, 'zarr_link')
        hdmfLinks = initLinkStruct();        

        for i = 1:numel(zAttributes.zarr_link)
            zarrLinkInfo = zAttributes.zarr_link(i);

            if isfield(zarrLinkInfo, 'name')
                hdmfLinks(i).Name = zarrLinkInfo.name;
            end
            if isfield(zarrLinkInfo, 'path')
                hdmfLinks(i).Value = {zarrLinkInfo.path};
            end
            if isfield(zarrLinkInfo, 'source')
                if strcmp(zarrLinkInfo.source, '.')
                    hdmfLinks(i).Type = 'soft link';
                else
                    hdmfLinks(i).Type = 'external link';
                    hdmfLinks(i).Value = {zarrLinkInfo.source, zarrLinkInfo.path};
                end
            end
        end
    end
end

function datatypeInfo = convertZarrDatatypeToH5(arrayMeta)
%CONVERTZARRDATATYPETOH5 Convert Zarr dtype to h5info datatype format

    datatypeInfo = struct();
    datatypeInfo.Name = '';
    datatypeInfo.Class = 'unknown';
    datatypeInfo.Size = 0;
    datatypeInfo.Attributes = initAttributeStruct();
    
end

function h5Dataspace = convertZarrDataspaceToH5(arrayMeta)
%CONVERTZARRDATASPACETOH5 Convert Zarr shape to h5info dataspace format
    
    h5Dataspace = struct();
    h5Dataspace.Size = [];
    h5Dataspace.MaxSize = [];
    h5Dataspace.Type = 'unknown';
    
    if isfield(arrayMeta, 'shape')
        shape = arrayMeta.shape;
        
        if isscalar(shape) && shape == 1
            h5Dataspace.Type = 'scalar';
            h5Dataspace.Size = [];
            h5Dataspace.MaxSize = [];
        else
            h5Dataspace.Type = 'simple';
            h5Dataspace.Size = shape;
            h5Dataspace.MaxSize = shape; % Zarr doesn't have unlimited dimensions
        end
    end
end

function h5Filters = convertZarrFiltersToH5(arrayMeta)
%CONVERTZARRFILTERSTOH5 Convert Zarr filters/compressor to h5info format

    h5Filters = struct('Name', {}, 'Parameters', {});
    
    % Add compression filter if present
    if isfield(arrayMeta, 'compressor') && ~isempty(arrayMeta.compressor)
        compressor = arrayMeta.compressor;
        
        filter = struct();
        if isfield(compressor, 'id')
            filter.Name = compressor.id;
        else
            filter.Name = 'unknown';
        end
        
        % Add compressor parameters
        filter.Parameters = compressor;
        h5Filters(end+1) = filter;
    end
    
    % Add additional filters if present
    if isfield(arrayMeta, 'filters') && ~isempty(arrayMeta.filters)
        filters = arrayMeta.filters;
        if ~iscell(filters)
            filters = {filters};
        end
        
        for i = 1:length(filters)
            filter = struct();
            if isfield(filters{i}, 'id')
                filter.Name = filters{i}.id;
            else
                filter.Name = 'unknown';
            end
            filter.Parameters = filters{i};
            h5Filters(end+1) = filter; %#ok<AGROW>
        end
    end
end

function S = initGroupStruct()
    S = struct('Name', {}, 'Groups', {}, 'Datasets', {}, 'Links', {}, 'Attributes', {});
end

function S = initDatasetStruct()
    S = struct('Name', {}, 'Datatype', {}, 'Dataspace', {}, 'ChunkSize', {}, 'FillValue', {}, 'Filters', {}, 'Attributes', {});
end

function S = initAttributeStruct()
    S = struct('Name', {}, 'Datatype', {}, 'Dataspace', {}, 'Value', {});
end

function S = initDataspaceStruct()
    S = struct('Size', [], 'MaxSize', [], 'Type', 'unknown');
end

function S = initLinkStruct()
    S = struct('Name', {}, 'Type', {}, 'Value', {});
end

function S = initDatatypeStruct()
    S = struct('Name', {}, 'Class', {}, 'Size', {}, 'Attributes', {});
end

%   Each Group structure contains:
%   - Name: The full path of the group
%   - Groups: Nested subgroups
%   - Datasets: Arrays/datasets in this group
%   - Links:
%   - Attributes: Group attributes
%
%   Each Dataset structure contains: TODO
%   - Name: Dataset name (without path)
%   - Datatype: Zarr datatype information
%   - Dataspace: Shape and dimension information
%   - ChunkSize: Chunk dimensions
%   - FillValue: Fill value
%   - Filters: Compression and filter information
%   - Attributes: Dataset attributes


function zmetadata = readMetadata(zarrFile)
    % Read .zmetadata file
    zmetadataFile = fullfile(zarrFile, '.zmetadata');
    if ~isfile(zmetadataFile)
        error("MATLAB:zarrinfo:missingZmetadata",...
            "No .zmetadata file found in %s. Use zarrconsolidate() first.", zarrFile);
    end
    
    % Parse JSON
    jsonStr = fileread(zmetadataFile);
    zmetadata = jsondecode(jsonStr);
    
    if ~isfield(zmetadata, 'metadata')
        error("MATLAB:zarrinfo:invalidZmetadata",...
            "Invalid .zmetadata format.");
    end
end


function [groupPaths, datasetPaths] = processKeys(metadata, keyMap)
    
    % Parse all metadata keys to build hierarchy
    matlabFieldNames = fieldnames(metadata);
    [groupPaths, datasetPaths] = deal({});
    
    % Separate groups and datasets
    for i = 1:length(matlabFieldNames)
        name = matlabFieldNames{i};
        if isKey(keyMap, name)
            key = keyMap(name);
        else
            key = name;
        end
        
        if endsWith(key, '/.zgroup') || endsWith(key, '_zgroup')
            % This is a group
            groupPath = extractPathFromKey(key, 'group');
            if ~strcmp(groupPath, '') % Not root group
                groupPaths{end+1} = groupPath; %#ok<AGROW>
            end
        elseif endsWith(key, '/.zarray') || endsWith(key, '_zarray')
            % This is a dataset/array
            datasetPath = extractPathFromKey(key, 'array');
            datasetPaths{end+1} = datasetPath; %#ok<AGROW>
        end
    end
    
    % Remove duplicates and sort (TODO: Should show warning if duplicates are present)
    groupPaths = unique(groupPaths);
    datasetPaths = unique(datasetPaths);
end

function zAttributes = getAttributes(metadata, elementPath, keyMap)
    attributeKey = [elementPath '/.zattrs'];
    
    if isKey(keyMap, attributeKey)
        fieldName = keyMap(attributeKey);
    else
        fieldName = '';
    end

    zAttributes = [];
    if isfield(metadata, fieldName)
        zAttributes = metadata.(fieldName);
    end
end

