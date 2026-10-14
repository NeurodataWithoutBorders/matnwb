classdef ReaderFake < io.backend.base.Reader
% ReaderFake - Reader that serves an in-memory node hierarchy.
%
% The hierarchy is an io.backend.model.GroupInfo for the root group.
% Attribute values are returned as listed, and dataset values are looked
% up by dataset path in a containers.Map. No dataset holds references.

    properties (SetAccess = private)
        RootInfo io.backend.model.GroupInfo

        % DatasetValues - containers.Map from dataset path to value.
        DatasetValues
    end

    methods
        function obj = ReaderFake(rootInfo, datasetValues)
            obj@io.backend.base.Reader("in-memory");
            obj.RootInfo = rootInfo;
            obj.DatasetValues = datasetValues;
        end

        function node = readRootInfo(obj)
            node = obj.RootInfo;
        end

        function node = readNodeInfo(obj, nodePath)
            names = split(strip(string(nodePath), "left", "/"), "/");
            node = obj.RootInfo;
            for iName = 1:numel(names)
                node = findChild(node, names(iName));
            end
        end

        function attributeValue = readAttributeValue(~, attributeInfo, ~)
            attributeValue = attributeInfo.Value;
        end

        function tf = isReferenceDataset(~, ~)
            tf = false;
        end

        function base = getExternalLinkBase(~)
            base = "/in-memory";
        end

        function datasetValue = readDatasetValue(obj, ~, datasetPath)
            datasetValue = obj.DatasetValues(char(datasetPath));
        end
    end
end

function child = findChild(groupInfo, name)
    candidates = {groupInfo.Groups, groupInfo.Datasets, groupInfo.Links};
    for iKind = 1:numel(candidates)
        nodes = candidates{iKind};
        isMatch = strcmp({nodes.Name}, name);
        if any(isMatch)
            child = nodes(isMatch);
            return
        end
    end
    error("NWB:Test:ReaderFake:NodeNotFound", ...
        "No node named `%s` in `%s`.", name, groupInfo.Path)
end
