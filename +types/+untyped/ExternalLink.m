classdef ExternalLink < handle
    properties
        name;
        filename;
        path;
    end
    
    methods
        function obj = ExternalLink(name, filename, path)
            obj.name = name;
            obj.filename = filename;
            obj.path = path;
        end
    end
    
    methods
        function data = deref(obj)
            % if path is valid hdf5 path, then returns either a Nwb Type or a DataStub
            assert(ischar(obj.filename), 'expecting filename to be a char array.');
            assert(2 == exist(obj.filename, 'file'), '%s does not exist.', obj.filename);
            
            File = h5.File.open(obj.filename);
            Descendent = File.get_descendent(obj.path);
            if isa(Descendent, 'h5.Link')
                Descendent = resolve_link_chain(Descendent, obj.filename, obj.path);
            end
            Attributes = Descendent.get_all_attributes();
            attribute_names = {Attributes.name};
            
            if any(strcmp(attribute_names, 'neurodata_type_def')...
                    | strcmp(attribute_names, 'data_type_def'))
                Nwb = nwbRead(obj.filename, 'ignorecache');
                data = io.resolvePath(Nwb, obj.path);
                return;
            end
            
            assert(isa(Descendent, 'h5.Dataset'),...
                'NWB:Untyped:ExternalLink:Deref:InvalidPath',...
                'External Links should point to a valid type or a dataset.');
            
            data = types.untyped.DataStub(obj.filename, obj.path);
            
            function Link = resolve_link_chain(Link, filename, path)
                LinkTraversalHistory = containers.Map(); % [filename -> {paths}]
                currentFilename = filename;
                currentPath = path;
                while isa(Link, 'h5.link.SoftLink')...
                        || isa(Link, 'h5.link.ExternalLink')
                    if LinkTraversalHistory.isKey(currentFilename)
                        assert(~any(strcmp(currentPath,...
                            LinkTraversalHistory(currentFilename))),...
                            'NWB:Untyped:ExternalLink:Deref:InfiniteLoopDetected',...
                            'Found a loop in Link chain from (`%s`, `%s`) to (`%s`, `%s`)',...
                            filename, path, currentFilename, currentPath);
                    else
                        LinkTraversalHistory(currentFilename) = {};
                    end
                    paths = LinkTraversalHistory(currentFilename);
                    paths{end+1} = currentPath;
                    LinkTraversalHistory(currentFilename) = paths;
                    
                    if isa(Link, 'types.untyped.SoftLink')
                        Link = io.resolvePath(Link.path);
                        currentPath = Link.path;
                    else
                        Link = Link.deref();
                        currentFilename = Link.filename;
                        currentPath = Link.path;
                    end
                end
            end
        end
        
        function MissingViews = export(obj, Parent, name)
            MissingViews = containers.Map.empty;
            
            Link = Parent.get_descendent(name);
            if ~isempty(Link)
                Parent.delete_link(name);
            end
            Parent.add_link(obj.path, 'filename', obj.filename);
        end
    end
    
    methods % IsNamed
        function name = get_name(obj)
            name = obj.name;
        end
    end
end