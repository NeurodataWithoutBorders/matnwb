classdef (Sealed) LinkInfo
% LinkInfo - Description of a link, as reported by a backend reader.
%
% A link is described without following it: its type and the location it
% points to. Type uses the vocabulary of h5info, which io.parseGroup
% checks with io.internal.h5.isValidLinkType.
%
% See also io.backend.base.Reader, io.backend.model.GroupInfo

    properties (SetAccess = immutable)
        % Name - Name of the link within its parent group.
        Name char = ''

        % Type - "soft link", "hard link" or "external link".
        Type char = ''

        % TargetPath - Path of the target within the file that holds it.
        TargetPath char = ''

        % TargetFile - File or store an external link points into, as
        % stored in the link; empty for other link types. A relative value
        % resolves against io.backend.base.Reader.getExternalLinkBase.
        TargetFile char = ''
    end

    methods
        function obj = LinkInfo(name, type, targetPath, targetFile)
        % LinkInfo - Create a link description.
        %
        % Syntax:
        %  obj = io.backend.model.LinkInfo(name, type, targetPath, targetFile)
        %
        % Input Arguments:
        %  - name - Name of the link within its parent group.
        %  - type - "soft link", "hard link" or "external link".
        %  - targetPath - Path of the target within the file that holds it.
        %  - targetFile - File or store an external link points into.
        %
        % All inputs are optional; omitted ones are empty.
            arguments
                name = ''
                type = ''
                targetPath = ''
                targetFile = ''
            end
            obj.Name = name;
            obj.Type = type;
            obj.TargetPath = targetPath;
            obj.TargetFile = targetFile;
        end
    end
end
