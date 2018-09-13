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
            oid = H5O.open(fid, obj.path, 'H5P_DEFAULT');
            oinfo = H5O.get_info(oid);
            assert(oinfo.type == H5ML.get_constant_value('H5G_DATASET'),...
                'Externally linked %s contains an unsupported type.',...
                [obj.filename obj.path]);
            data = H5D.read(oid);
            H5O.close(oid);
            H5F.close(fid);
        end
        
        function refs = export(obj, fid, fullpath, refs)
            plist = 'H5P_DEFAULT';
            H5L.create_external(obj.filename, obj.path, fid, fullpath, plist, plist);
        end
    end
end