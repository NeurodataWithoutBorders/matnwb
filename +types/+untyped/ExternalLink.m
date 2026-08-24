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
            for i = 1:numel(obj)
                data{i} = scalar_deref(obj(i));
            end
            
            if isscalar(data)
                data = data{1};
            end
            
            function data = scalar_deref(Link)
                % Returns an NWB object, DataStub, or Link object for a
                % valid target path; errors otherwise.
                assert(ischar(Link.filename), 'expecting filename to be a char array.');
                % A store is a file for some backends and a directory for
                % others, so existence is checked without assuming either.
                assert(isfile(Link.filename) || isfolder(Link.filename), ...
                    'NWB:ExternalLink:TargetNotFound', ...
                    '%s does not exist.', Link.filename);

                reader = io.backend.BackendFactory.createReader(Link.filename);
                LinkedInfo = reader.readNodeInfo(Link.path);
                loc = [Link.filename Link.path];
                
                if isfield(LinkedInfo, 'Attributes')
                    attr_names = {LinkedInfo.Attributes.Name};
                    is_typed = any(strcmp(attr_names, 'neurodata_type')...
                        | strcmp(attr_names, 'namespace'));
                else
                    is_typed = false;
                end
                
                is_dataset = all(isfield(LinkedInfo, {...
                    'FillValue',...
                    'ChunkSize',...
                    'Dataspace',...
                    'Datatype',...
                    'Filters',...
                    'Attributes'}));
                is_group = all(isfield(LinkedInfo, {...
                    'Groups',...
                    'Datasets',...
                    'Datatypes',...
                    'Links',...
                    'Attributes'}));
                is_link = all(isfield(LinkedInfo, {...
                    'Type',...
                    'Value'
                    }));
                assert(is_dataset || is_group || is_link,...
                    'NWB:ExternalLink:UnknownNodeType',...
                    'Unsupported externally linked type (not a group, dataset, or link!');
                assert(1 == sum([is_dataset is_group is_link]),...
                    'NWB:ExternalLink:AmbiguousNodeType',...
                    'Externally linked type is ambiguous! (cannot discern between group, dataset, or link!)');
                
                if is_dataset
                    % typed objects and references are handled by io.parseDataset
                    is_reference = strcmp(LinkedInfo.Datatype.Class, 'H5T_REFERENCE');
                    if is_typed || is_reference
                        parsed = io.parseDataset(Link.filename, LinkedInfo, Link.path, ...
                            io.internal.defaultParseExclusions(), reader);
                        data = parsed(LinkedInfo.Name);
                    else
                        data = types.untyped.DataStub(Link.filename, Link.path);
                    end
                elseif is_group
                    assert(is_typed,...
                        'NWB:ExternalLink:UntypedGroup',...
                        ['MatNWB cannot return a non-typed group. Please return the parent '...
                        'typed object that contains `%s`'], loc);
                    data = io.parseGroup(Link.filename, LinkedInfo, ...
                        io.internal.defaultParseExclusions(), reader);
                else % link
                    data = deref_link(reader, Link);
                end
            end
            
            function data = deref_link(reader, Link)
                linkInfo = reader.readLinkInfo(Link.path);
                if linkInfo.Type == "external link"
                    data = types.untyped.ExternalLink(...
                        linkInfo.TargetFilename, linkInfo.TargetPath);
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
end
