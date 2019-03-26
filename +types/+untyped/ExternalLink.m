classdef ExternalLink < handle
    properties
        filename;
        path;
    end
    
    methods
        function obj = ExternalLink(filename, path)
            obj.filename = filename;
            obj.path = path;
        end
        
        function data = deref(obj)
            fid = H5F.open(obj.filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
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
                        data = h5read(obj.filename, obj.path);
                    end
                case H5ML.get_constant_value('H5G_GROUP')
                    if is_typed
                        data = io.parseGroup(obj.filename, info);
                    else
                        error('Attempted to dereference an external link to a non-dataset object %s',...
                            loc);
                    end
                case H5ML.get_constant_value('H5G_LINK')
                    error('Attempted to dereference into another link %s.  Resolving Link chains is not implemented.', loc);
                otherwise
                    error('Externally linked %s contains an unsupported type.',...
                        loc);
            end
        end
        
        function refs = export(obj, fid, fullpath, refs)
            plist = 'H5P_DEFAULT';
            H5L.create_external(obj.filename, obj.path, fid, fullpath, plist, plist);
        end
    end
end