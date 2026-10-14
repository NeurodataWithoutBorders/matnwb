function [rootInfo, nodeInfoMap] = buildNodeInfo(rootGroup)
% buildNodeInfo - Describe the hierarchy below a zarr.Group root.
%
% [rootInfo, nodeInfoMap] = buildNodeInfo(rootGroup) walks the hierarchy
% below rootGroup (a zarr.Group opened via zarr.open, using its
% consolidated metadata when available) and returns:
%
%     rootInfo - io.backend.model.GroupInfo describing the root group and,
%       through its child groups, the whole hierarchy.
%
%     nodeInfoMap - containers.Map from absolute node path (char, leading
%       '/') to the io.backend.model.GroupInfo, DatasetInfo or LinkInfo
%       describing that node. Links are recorded under their own path, so
%       a link is described without following it.
%
% The BackendInfo of each DatasetInfo is a struct with the fields:
%
%     Shape - Array shape in Zarr (row-major) order; empty for rank 0.
%     ChunkShape - Chunk shape in Zarr order.
%     DataType - Zarr v3 data_type name, e.g. "int64", "string", "struct".
%     Kind - "reference" for an hdmf-zarr object reference array,
%       "compound" for a structured array, and "array" otherwise.

    nodeInfoMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
    rootInfo = buildGroupInfo(rootGroup, "/", nodeInfoMap);
end

function groupInfo = buildGroupInfo(group, groupPath, nodeInfoMap)
    [attributes, links] = io.internal.zarr3.convertAttributes(group.attrs);
    for iLink = 1:numel(links)
        linkPath = joinPath(groupPath, links(iLink).Name);
        nodeInfoMap(char(linkPath)) = links(iLink);
    end

    [arrayNames, groupNames] = group.children();

    datasets = io.backend.model.DatasetInfo.empty(0, 1);
    for iArray = numel(arrayNames):-1:1
        childArray = group.item(arrayNames(iArray));
        datasetInfo = buildDatasetInfo(childArray, arrayNames(iArray));
        datasets(iArray, 1) = datasetInfo;
        nodeInfoMap(char(joinPath(groupPath, arrayNames(iArray)))) = datasetInfo;
    end

    groups = io.backend.model.GroupInfo.empty(0, 1);
    for iGroup = numel(groupNames):-1:1
        childGroup = group.item(groupNames(iGroup));
        childPath = joinPath(groupPath, groupNames(iGroup));
        groups(iGroup, 1) = buildGroupInfo(childGroup, childPath, nodeInfoMap);
    end

    groupInfo = io.backend.model.GroupInfo(groupPath, Groups=groups, ...
        Datasets=datasets, Links=links, Attributes=attributes);

    % nodeInfoMap is a containers.Map (a handle), so this insertion is seen
    % by the caller even though nodeInfoMap is not returned from here.
    nodeInfoMap(char(groupPath)) = groupInfo; %#ok<NASGU>
end

function datasetInfo = buildDatasetInfo(arrayNode, leafName)
    dataType = string(arrayNode.dtype);

    % Object references have no native Zarr v3 type: hdmf-zarr stores them
    % as a string array of target paths tagged _DTYPE:"object_reference"
    % (detected by hdmf.zarr.isReferenceArray, decoded by
    % hdmf.zarr.Reference). Any other _DTYPE hint is redundant with the
    % native Zarr v3 data_type and ignored; the attribute itself is
    % reserved and filtered out of the attributes by
    % io.internal.zarr3.convertAttributes. zarr-python 3.4 names the
    % structured data type "struct"; earlier versions wrote "structured".
    if hdmf.zarr.isReferenceArray(arrayNode)
        kind = "reference";
    elseif any(dataType == ["struct", "structured"])
        kind = "compound";
    else
        kind = "array";
    end

    backendInfo = struct( ...
        'Shape', double(arrayNode.shape), ...
        'ChunkShape', double(arrayNode.chunkShape), ...
        'DataType', dataType, ...
        'Kind', kind);
    datasetInfo = io.backend.model.DatasetInfo(leafName, ...
        io.internal.zarr3.convertAttributes(arrayNode.attrs), backendInfo);
end

function joinedPath = joinPath(parentPath, childName)
    if parentPath == "/"
        joinedPath = "/" + childName;
    else
        joinedPath = parentPath + "/" + childName;
    end
end
