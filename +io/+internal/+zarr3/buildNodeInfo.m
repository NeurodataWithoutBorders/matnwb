function [rootInfo, nodeInfoMap] = buildNodeInfo(rootGroup)
% buildNodeInfo - Build an h5info-like node tree from a zarr.Group root.
%
%   [rootInfo, nodeInfoMap] = buildNodeInfo(rootGroup) walks the hierarchy
%   below rootGroup (a zarr.Group opened via zarr.open, using its
%   consolidated metadata when available) and returns:
%
%     rootInfo - h5info-like struct for the root node (fields Name, Groups,
%       Datasets, Links, Attributes), recursively populated.
%
%     nodeInfoMap - containers.Map from absolute node path (char, leading
%       '/') to the corresponding node info struct (group or dataset).
%
%   The output shape mirrors h5info's, so io.parseGroup/io.parseDataset/
%   io.parseAttributes can consume it directly.

    nodeInfoMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
    rootInfo = buildGroupInfo(rootGroup, "/", nodeInfoMap);
end

function groupInfo = buildGroupInfo(group, groupPath, nodeInfoMap)
    groupInfo = struct(...
        'Name', char(groupPath), ...
        'Groups', emptyGroupStruct(), ...
        'Datasets', emptyDatasetStruct(), ...
        'Links', emptyLinkStruct(), ...
        'Attributes', emptyAttributeStruct());

    [attributes, links] = io.internal.zarr3.convertAttributes(group.attrs);
    groupInfo.Attributes = attributes;
    groupInfo.Links = links;

    [arrayNames, groupNames] = group.children();

    for iArray = 1:numel(arrayNames)
        childArray = group.item(arrayNames(iArray));
        childPath = joinPath(groupPath, arrayNames(iArray));
        datasetInfo = buildDatasetInfo(childArray, arrayNames(iArray));
        groupInfo.Datasets(end+1) = datasetInfo; %#ok<AGROW>
        nodeInfoMap(char(childPath)) = datasetInfo;
    end

    for iGroup = 1:numel(groupNames)
        childGroup = group.item(groupNames(iGroup));
        childPath = joinPath(groupPath, groupNames(iGroup));
        childInfo = buildGroupInfo(childGroup, childPath, nodeInfoMap);
        groupInfo.Groups(end+1) = childInfo; %#ok<AGROW>
    end

    nodeInfoMap(char(groupPath)) = groupInfo;
end

function datasetInfo = buildDatasetInfo(arrayNode, leafName)
    shape = double(arrayNode.shape);
    if isempty(shape)
        dataspaceType = 'scalar';
    else
        dataspaceType = 'simple';
    end

    datasetInfo = struct(...
        'Name', char(leafName), ...
        'Datatype', char(arrayNode.dtype), ...
        'Dataspace', struct('Size', shape, 'MaxSize', shape, 'Type', dataspaceType), ...
        'ChunkSize', double(arrayNode.chunkShape), ...
        'FillValue', arrayNode.meta.fillValue, ...
        'Filters', struct('Name', {}, 'Parameters', {}), ...
        'Attributes', emptyAttributeStruct());

    % A "zarr_dtype" attribute (reserved; filtered out of Attributes below)
    % is a legacy hdmf-zarr (v2) dtype hint. For plain numeric/string data
    % it is normally redundant with (and less precise than) the native
    % Zarr v3 `data_type`, so it is ignored -- except for two semantic
    % markers with no native Zarr v3 equivalent, which override Datatype
    % so io.backend.zarr3.Zarr3Reader can dispatch on them:
    %   "object" - an array of object references stored as JSON-encoded
    %     strings.
    %   "scalar" - hdmf-zarr represents an NWB scalar property (e.g.
    %     identifier, session_description) as a rank-1, length-1 Zarr
    %     array rather than a true rank-0 array, so shape alone cannot
    %     distinguish it from a genuine one-row VectorData column (e.g. a
    %     DynamicTable that happens to have a single row) -- both have
    %     Dataspace.Size == 1. Reading the latter eagerly as a bare scalar
    %     would silently collapse a 1-element char/string column, whose
    %     stray character count would then be misread as a table row
    %     count by DynamicTable height checks.
    % For a "structured" (compound) array, this attribute is instead a
    % per-field type descriptor list (a struct array), not a scalar
    % string -- irrelevant here since the array's own Zarr v3 data_type
    % ("structured") already identifies it unambiguously.
    zarrDtypeAttr = [];
    if isfield(arrayNode.attrs, 'zarr_dtype')
        zarrDtypeAttr = arrayNode.attrs.zarr_dtype;
    end
    if ischar(zarrDtypeAttr) || isstring(zarrDtypeAttr)
        zarrDtypeAttrText = string(zarrDtypeAttr);
        if zarrDtypeAttrText == "object"
            datasetInfo.Datatype = 'object';
        elseif zarrDtypeAttrText == "scalar"
            datasetInfo.Datatype = 'scalar';
        end
    end

    datasetInfo.Attributes = io.internal.zarr3.convertAttributes(arrayNode.attrs);
end

function joinedPath = joinPath(parentPath, childName)
    if parentPath == "/"
        joinedPath = "/" + childName;
    else
        joinedPath = parentPath + "/" + childName;
    end
end

function groupStruct = emptyGroupStruct()
    groupStruct = struct('Name', {}, 'Groups', {}, 'Datasets', {}, 'Links', {}, 'Attributes', {});
end

function datasetStruct = emptyDatasetStruct()
    datasetStruct = struct('Name', {}, 'Datatype', {}, 'Dataspace', {}, ...
        'ChunkSize', {}, 'FillValue', {}, 'Filters', {}, 'Attributes', {});
end

function attributeStruct = emptyAttributeStruct()
    attributeStruct = struct('Name', {}, 'Datatype', {}, 'Dataspace', {}, 'Value', {});
end

function linkStruct = emptyLinkStruct()
    linkStruct = struct('Name', {}, 'Type', {}, 'Value', {});
end
