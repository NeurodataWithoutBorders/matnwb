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
                % A URL is not checked here: creating its reader fetches it.
                assert(matnwb.common.isUrl(targetFilename) ...
                    || isfile(targetFilename) || isfolder(targetFilename), ...
                    'NWB:ExternalLink:TargetNotFound', ...
                    '%s does not exist.', targetFilename);

                reader = io.backend.BackendFactory.createReader(targetFilename);
                linkedInfo = reader.readNodeInfo(link.path);
                location = [targetFilename link.path];

                if isa(linkedInfo, 'io.backend.model.LinkInfo')
                    data = derefLink(reader, linkedInfo);
                    return
                end

                attributeNames = {linkedInfo.Attributes.Name};
                isTyped = any(strcmp(attributeNames, 'neurodata_type')...
                    | strcmp(attributeNames, 'namespace'));

                if isa(linkedInfo, 'io.backend.model.DatasetInfo')
                    % typed objects and references are handled by io.parseDataset
                    isReference = reader.isReferenceDataset(linkedInfo);
                    if isTyped || isReference
                        parsed = io.parseDataset(targetFilename, linkedInfo, link.path, ...
                            io.internal.defaultParseExclusions(), reader);
                        data = parsed(linkedInfo.Name);
                    else
                        data = types.untyped.DataStub(targetFilename, link.path);
                    end
                else % group
                    assert(isTyped,...
                        'NWB:ExternalLink:UntypedGroup',...
                        ['MatNWB cannot return a non-typed group. Please return the parent '...
                        'typed object that contains `%s`'], location);
                    data = io.parseGroup(targetFilename, linkedInfo, ...
                        io.internal.defaultParseExclusions(), reader);
                end
            end

            function data = derefLink(reader, linkInfo)
                if strcmp(linkInfo.Type, 'external link')
                    % The chained link lives in the target file, so its
                    % relative filename resolves against that file's base.
                    data = types.untyped.ExternalLink(...
                        linkInfo.TargetFile, linkInfo.TargetPath, ...
                        reader.getExternalLinkBase());
                else
                    data = types.untyped.SoftLink(linkInfo.TargetPath);
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
            if isempty(obj.BasePath) || isAbsolutePath(targetFilename)
                return
            end
            if matnwb.common.isUrl(obj.BasePath)
                targetFilename = resolveRelativeUrl(obj.BasePath, targetFilename);
            else
                targetFilename = char(fullfile(obj.BasePath, targetFilename));
            end
        end
    end
end

function url = resolveRelativeUrl(baseUrl, relativePath)
% resolveRelativeUrl - Join a relative path onto a URL, applying "." and "..".
%
% fullfile cannot be used for a URL: it collapses the "//" after the scheme.
    parts = regexp(char(baseUrl), '^(https?://[^/]+)(.*)$', 'tokens', 'once', 'ignorecase');
    segments = split(string(parts{2}), "/");
    segments(segments == "") = [];
    for segment = reshape(split(string(relativePath), ["/", "\"]), 1, [])
        if segment == "" || segment == "."
            continue
        elseif segment == ".."
            if ~isempty(segments)
                segments(end) = [];
            end
        else
            segments(end+1) = segment; %#ok<AGROW>
        end
    end
    url = char(string(parts{1}) + "/" + strjoin(segments, "/"));
end

function tf = isAbsolutePath(pathName)
% A link target written on another platform may use either separator, so
% both are accepted when testing for a Windows drive or UNC prefix. A URL is
% absolute.
if matnwb.common.isUrl(pathName)
    tf = true;
elseif ispc
    tf = ~isempty(regexp(pathName, '^([A-Za-z]:[\\/]|[\\/][\\/])', 'once'));
else
    tf = startsWith(pathName, '/');
end
end
