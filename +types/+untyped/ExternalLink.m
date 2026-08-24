classdef ExternalLink < handle
    properties
        filename;
        path;
    end
    
    methods
        function obj = ExternalLink(filename, path)
            validateattributes(filename, {'char', 'string'}, {'scalartext'} ...
                , 'types.untyped.ExternalLink', 'filename', 1);
            validateattributes(path, {'char', 'string'}, {'scalartext'} ...
                , 'types.untyped.ExternalLink', 'path', 2);
            obj.filename = char(filename);
            obj.path = char(path);
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
                % A store is a file for some backends and a directory for
                % others, so existence is checked without assuming either.
                assert(isfile(link.filename) || isfolder(link.filename), ...
                    'NWB:ExternalLink:TargetNotFound', ...
                    '%s does not exist.', link.filename);

                reader = io.backend.BackendFactory.createReader(link.filename);
                linkedInfo = reader.readNodeInfo(link.path);
                location = [link.filename link.path];

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
                isGroup = all(isfield(linkedInfo, {...
                    'Groups',...
                    'Datasets',...
                    'Datatypes',...
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
                        parsed = io.parseDataset(link.filename, linkedInfo, link.path, ...
                            io.internal.defaultParseExclusions(), reader);
                        data = parsed(linkedInfo.Name);
                    else
                        data = types.untyped.DataStub(link.filename, link.path);
                    end
                elseif isGroup
                    assert(isTyped,...
                        'NWB:ExternalLink:UntypedGroup',...
                        ['MatNWB cannot return a non-typed group. Please return the parent '...
                        'typed object that contains `%s`'], location);
                    data = io.parseGroup(link.filename, linkedInfo, ...
                        io.internal.defaultParseExclusions(), reader);
                else % link
                    data = derefLink(reader, link);
                end
            end

            function data = derefLink(reader, link)
                linkInfo = reader.readLinkInfo(link.path);
                if linkInfo.type == "external link"
                    data = types.untyped.ExternalLink(...
                        linkInfo.targetFilename, linkInfo.targetPath);
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
end
