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
            
            Nwb = nwbRead(obj.filename, 'ignorecache');
            SubObj = io.resolvePath(Nwb, obj.path);
            
            if isa(SubObj, 'types.untyped.SoftLink')...
                    || isa(SubObj, 'types.untyped.ExternalLink')
                SubObj = resolve_link_chain(SubObj, obj.filename, obj.path);
            end
            
            info = h5info(obj.filename, obj.path);
            loc = [obj.filename obj.path];
            attr_names = {info.Attributes.Name};
            
            is_typed = any(strcmp(attr_names, 'neurodata_type')...
                | strcmp(attr_names, 'namespace'));
            
            oid = H5O.open(fid, obj.path, 'H5P_DEFAULT');
            oinfo = H5O.get_info(oid);
            
            H5O.close(oid);
            H5F.close(fid);
            switch oinfo.type
                case H5ML.get_constant_value('H5G_DATASET')
                    if is_typed
                        data = io.parseDataset(obj.filename, info, obj.path);
                    else
                        data = types.untyped.DataStub(obj.filename, obj.path);
                    end
                case H5ML.get_constant_value('H5G_GROUP')
                    assert(is_typed,...
                        ['Attempted to dereference an external link to '...
                        'a non-dataset object %s'], loc);
                    data = io.parseGroup(obj.filename, info);
                case H5ML.get_constant_value('H5G_LINK')
                    data = deref_link(fid, obj.path);
                otherwise
                    error('Externally linked %s contains an unsupported type.',...
                        loc);
            end
            
            function resolve_link_chain(SubObj, filename, path)
                LinkTraversalHistory = containers.Map(); % [filename -> {paths}]
                currentFilename = filename;
                currentPath = path;
                while isa(SubObj, 'types.untyped.SoftLink')...
                        || isa(SubObj, 'types.untyped.ExternalLink')
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
                    
                    if isa(SubObj, 'types.untyped.SoftLink')
                        SubObj = io.resolvePath(SubObj.path);
                        currentPath = SubObj.path;
                    else
                        SubObj = SubObj.deref();
                        currentFilename = SubObj.filename;
                        currentPath = SubObj.path;
                    end
                end
            end
            
            function data = deref_link(fid, path)
                linfo = H5L.get_info(fid, path, 'H5P_DEFAULT');
                is_external = linfo.type == H5ML.get_constant_value('H5L_TYPE_EXTERNAL');
                is_soft = linfo.type == H5ML.get_constant_value('H5L_TYPE_SOFT');
                assert(is_external || is_soft,...
                    ['Unsupported link type in %s, with name %s.  '...
                    'Links must be external or soft.'],...
                    obj.filename, path);
                
                link_val = H5L.get_val(fid, path, 'H5P_DEFAULT');
                if is_external
                    data = types.untyped.ExternalLink(link_val{:});
                else
                    data = types.untyped.SoftLink(link_val{:});
                end
            end
        end
        
        function refs = export(obj, fid, fullpath, refs)
            plist = 'H5P_DEFAULT';
            if H5L.exists(fid, fullpath, plist)
                H5L.delete(fid, fullpath, plist);
            end
            H5L.create_external(obj.filename, obj.path, fid, fullpath, plist, plist);
        end
    end
    
    methods % IsNamed
        function name = get_name(obj)
            name = obj.name;
        end
    end
end