function [rootInfo, nodeInfoMap] = buildNodeInfo(rootGroup)
% buildNodeInfo - Build an h5info-like node tree from a zarr.Group root.
%
% [rootInfo, nodeInfoMap] = buildNodeInfo(rootGroup) walks the hierarchy
% below rootGroup (a zarr.Group opened via zarr.open, using its
% consolidated metadata when available) and returns:
%
%     rootInfo - h5info-like struct for the root node (fields Name, Groups,
%       Datasets, Links, Attributes), recursively populated.
%
%     nodeInfoMap - containers.Map from absolute node path (char, leading
%       '/') to the corresponding node info struct (group or dataset).
%
% The output shape mirrors h5info's, so io.parseGroup/io.parseDataset/
% io.parseAttributes can consume it directly.

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

    % Two hdmf-zarr semantic markers have no native Zarr v3 equivalent and
    % override Datatype so io.backend.zarr3.Zarr3Reader can dispatch on them:
    % "object" - a dataset of object references (string array of JSON
    %     reference records tagged zarr_dtype:"object"; detected by
    %     hdmf.zarr.isReferenceArray, decoded by hdmf.zarr.Reference).
    % "scalar" - hdmf-zarr represents an NWB scalar property (e.g.
    %     identifier, session_description) as a rank-1, length-1 Zarr
    %     array tagged zarr_dtype:"scalar" rather than a true rank-0 array,
    %     so shape alone cannot distinguish it from a genuine one-row
    %     VectorData column (e.g. a DynamicTable that happens to have a
    %     single row) -- both have Dataspace.Size == 1. Reading the latter
    %     eagerly as a bare scalar would silently collapse a 1-element
    %     char/string column, whose stray character count would then be
    %     misread as a table row count by DynamicTable height checks.
    % Any other zarr_dtype hint (a plain dtype name, or the per-field
    % descriptor list of a "structured" array) is redundant with the native
    % Zarr v3 data_type and ignored; the attribute itself is reserved and
    % filtered out of Attributes by io.internal.zarr3.convertAttributes.
    if hdmf.zarr.isReferenceArray(arrayNode)
        datasetInfo.Datatype = 'object';
    elseif isScalarMarked(arrayNode.attrs)
        datasetInfo.Datatype = 'scalar';
    end

    datasetInfo.Attributes = io.internal.zarr3.convertAttributes(arrayNode.attrs);
end

function tf = isScalarMarked(attrs)
% isScalarMarked - True if attrs carries hdmf-zarr's zarr_dtype:"scalar" hint.
    tf = false;
    if ~isfield(attrs, 'zarr_dtype')
        return
    end
    zarrDtype = attrs.zarr_dtype;
    tf = (ischar(zarrDtype) || isstring(zarrDtype)) && string(zarrDtype) == "scalar";
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
