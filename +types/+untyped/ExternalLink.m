classdef ExternalLink < handle
    properties
        filename;
        path;
    end

    properties (Hidden, SetAccess = private)
        % Base location a relative `filename` resolves against, captured
        % from the backend reader when the link is read from a file. Left
        % empty for user-constructed links, which keep resolving against
        % the working directory.
        BasePath = '';
    end

    methods
        function obj = ExternalLink(filename, path, basePath)
            validateattributes(filename, {'char', 'string'}, {'scalartext'} ...
                , 'types.untyped.ExternalLink', 'filename', 1);
            validateattributes(path, {'char', 'string'}, {'scalartext'} ...
                , 'types.untyped.ExternalLink', 'path', 2);
            obj.filename = char(filename);
            obj.path = char(path);
            if nargin > 2
                validateattributes(basePath, {'char', 'string'}, {'scalartext'} ...
                    , 'types.untyped.ExternalLink', 'basePath', 3);
                obj.BasePath = char(basePath);
            end
        end
        
        function data = deref(obj)
            data = cell(size(obj));
            for iLink = 1:numel(obj)
                data{iLink} = scalarDeref(obj(iLink));
            end

            if isscalar(data)
                data = data{1};
            end

            function data = scalarDeref(link)
                % Returns an NWB object, DataStub, or Link object for a
                % valid target path; errors otherwise.
                assert(ischar(link.filename), 'expecting filename to be a char array.');
                targetFilename = link.resolveTargetFilename();
                % A store is a file for some backends and a directory for
                % others, so existence is checked without assuming either.
                assert(isfile(targetFilename) || isfolder(targetFilename), ...
                    'NWB:ExternalLink:TargetNotFound', ...
                    '%s does not exist.', targetFilename);

                reader = io.backend.BackendFactory.createReader(targetFilename);
                linkedInfo = reader.readNodeInfo(link.path);
                location = [targetFilename link.path];

                % The field names tested below are h5info's, which
                % io.backend.base.Reader.readNodeInfo mirrors for every
                % backend, so the node classification stays backend neutral.
                if isfield(linkedInfo, 'Attributes')
                    attributeNames = {linkedInfo.Attributes.Name};
                    isTyped = any(strcmp(attributeNames, 'neurodata_type')...
                        | strcmp(attributeNames, 'namespace'));
                else
                    isTyped = false;
                end

                isDataset = all(isfield(linkedInfo, {...
                    'FillValue',...
                    'ChunkSize',...
                    'Dataspace',...
                    'Datatype',...
                    'Filters',...
                    'Attributes'}));
                % 'Datatypes' is deliberately not required: it holds HDF5
                % named datatypes, which have no equivalent in other
                % backends, and nothing reads it. Groups, Datasets and Links
                % already tell a group apart from a dataset or a link.
                isGroup = all(isfield(linkedInfo, {...
                    'Groups',...
                    'Datasets',...
                    'Links',...
                    'Attributes'}));
                isLink = all(isfield(linkedInfo, {...
                    'Type',...
                    'Value'
                    }));
                assert(isDataset || isGroup || isLink,...
                    'NWB:ExternalLink:UnknownNodeType',...
                    'Unsupported externally linked type (not a group, dataset, or link!');
                assert(1 == sum([isDataset isGroup isLink]),...
                    'NWB:ExternalLink:AmbiguousNodeType',...
                    'Externally linked type is ambiguous! (cannot discern between group, dataset, or link!)');

                if isDataset
                    % typed objects and references are handled by io.parseDataset
                    isReference = reader.isReferenceDataset(linkedInfo);
                    if isTyped || isReference
                        parsed = io.parseDataset(targetFilename, linkedInfo, link.path, ...
                            io.internal.defaultParseExclusions(), reader);
                        data = parsed(linkedInfo.Name);
                    else
                        data = types.untyped.DataStub(targetFilename, link.path);
                    end
                elseif isGroup
                    assert(isTyped,...
                        'NWB:ExternalLink:UntypedGroup',...
                        ['MatNWB cannot return a non-typed group. Please return the parent '...
                        'typed object that contains `%s`'], location);
                    data = io.parseGroup(targetFilename, linkedInfo, ...
                        io.internal.defaultParseExclusions(), reader);
                else % link
                    data = derefLink(reader, link);
                end
            end

            function data = derefLink(reader, link)
                linkInfo = reader.readLinkInfo(link.path);
                if linkInfo.type == "external link"
                    % The chained link lives in the target file, so its
                    % relative filename resolves against that file's base.
                    data = types.untyped.ExternalLink(...
                        linkInfo.targetFilename, linkInfo.targetPath, ...
                        reader.getExternalLinkBase());
                else
                    data = types.untyped.SoftLink(linkInfo.targetPath);
                end
            end
        end
        
        function refs = export(obj, writer, fullpath, refs)
            if nargin < 4; refs = {}; end
            writer = io.backend.base.Writer.ensure(writer);
            writer.writeExternalLink(fullpath, obj.filename, obj.path);
        end
    end

    methods (Access = private)
        function targetFilename = resolveTargetFilename(obj)
            % A relative target resolves against BasePath when the link was
            % read from a file; otherwise it is returned as given and
            % resolves against the working directory.
            targetFilename = obj.filename;
            if ~isempty(obj.BasePath) && ~isAbsolutePath(targetFilename)
                targetFilename = char(fullfile(obj.BasePath, targetFilename));
            end
        end
    end
end

function tf = isAbsolutePath(pathName)
% A link target written on another platform may use either separator, so
% both are accepted when testing for a Windows drive or UNC prefix.
if ispc
    tf = ~isempty(regexp(pathName, '^([A-Za-z]:[\\/]|[\\/][\\/])', 'once'));
else
    tf = startsWith(pathName, '/');
end
end
