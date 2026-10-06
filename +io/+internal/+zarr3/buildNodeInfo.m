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
        groupInfo.Datasets(end+1) = datasetInfo;
        nodeInfoMap(char(childPath)) = datasetInfo;
    end

    for iGroup = 1:numel(groupNames)
        childGroup = group.item(groupNames(iGroup));
        childPath = joinPath(groupPath, groupNames(iGroup));
        childInfo = buildGroupInfo(childGroup, childPath, nodeInfoMap);
        groupInfo.Groups(end+1) = childInfo;
    end

    % nodeInfoMap is a containers.Map (a handle), so this insertion is seen
    % by the caller even though nodeInfoMap is not returned from here.
    nodeInfoMap(char(groupPath)) = groupInfo; %#ok<NASGU>
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

    % Object references have no native Zarr v3 type: hdmf-zarr stores them
    % as a string array of target paths tagged _DTYPE:"object_reference"
    % (detected by hdmf.zarr.isReferenceArray, decoded by
    % hdmf.zarr.Reference). Datatype is overridden to "object" so that
    % io.backend.zarr3.Zarr3Reader can dispatch on it. Any other _DTYPE hint
    % is redundant with the native Zarr v3 data_type and ignored; the
    % attribute itself is reserved and filtered out of Attributes by
    % io.internal.zarr3.convertAttributes.
    if hdmf.zarr.isReferenceArray(arrayNode)
        datasetInfo.Datatype = 'object';
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
