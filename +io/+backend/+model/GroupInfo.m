classdef (Sealed) GroupInfo
% GroupInfo - Description of a group, as reported by a backend reader.
%
% A group is described by its absolute path, its child groups and
% datasets, the links it holds and its attributes. Child groups are
% described the same way, so the GroupInfo of the root group describes
% the whole hierarchy.
%
% See also io.backend.base.Reader, io.backend.model.DatasetInfo,
%   io.backend.model.LinkInfo, io.backend.model.AttributeInfo

    properties (SetAccess = immutable)
        % Path - Absolute path of the group; "/" for the root group.
        Path char = '/'

        % Name - Last element of Path; empty for the root group.
        Name char = ''

        % Groups - Child groups.
        Groups (:,1) io.backend.model.GroupInfo

        % Datasets - Child datasets.
        Datasets (:,1) io.backend.model.DatasetInfo

        % Links - Links held by the group.
        Links (:,1) io.backend.model.LinkInfo

        % Attributes - Attributes of the group.
        Attributes (:,1) io.backend.model.AttributeInfo
    end

    methods
        function obj = GroupInfo(path, options)
        % GroupInfo - Create a group description.
        %
        % Syntax:
        %  obj = io.backend.model.GroupInfo(path) describes an empty group.
        %
        %  obj = io.backend.model.GroupInfo(path, Name=Value) describes a
        %  group with the child nodes and attributes given as name-value
        %  arguments.
        %
        % Input Arguments:
        %  - path - Absolute path of the group. Default: "/".
        %
        % Name-Value Arguments:
        %  - Groups - GroupInfo array describing the child groups.
        %  - Datasets - DatasetInfo array describing the child datasets.
        %  - Links - LinkInfo array describing the links in the group.
        %  - Attributes - AttributeInfo array describing the attributes.
            arguments
                path = '/'
                options.Groups = io.backend.model.GroupInfo.empty(0, 1)
                options.Datasets = io.backend.model.DatasetInfo.empty(0, 1)
                options.Links = io.backend.model.LinkInfo.empty(0, 1)
                options.Attributes = io.backend.model.AttributeInfo.empty(0, 1)
            end
            obj.Path = path;
            [~, name] = io.pathParts(obj.Path);
            obj.Name = name;
            obj.Groups = options.Groups;
            obj.Datasets = options.Datasets;
            obj.Links = options.Links;
            obj.Attributes = options.Attributes;
        end
    end
end
