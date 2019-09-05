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
            % if path is valid hdf5 path, then returns either a Nwb Object, DataStub or a Link.
            % otherwise, returns the file id of the referenced link.
            assert(ischar(obj.filename), 'expecting filename to be a char array.');
            assert(2 == exist(obj.filename, 'file'), '%s does not exist.', obj.filename);
            
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
            H5L.create_external(obj.filename, obj.path, fid, fullpath, plist, plist);
        end
    end
end