classdef NWBContainer
    properties %name
        name;
    end
    
    properties %attributes
        help;
    end
    
    properties %extensions
        attributes = struct([]);
        datasets = struct([]);
        groups = struct([]);
    end
    
    methods
        function obj = NWBContainer(name, help, attributes, datasets, groups)
            obj.name = name;
            obj.help = help;
            obj.attributes = attributes;
            obj.datasets = datasets;
            obj.groups = groups;
        end
        
        function hdf_obj = export(obj, fid, path)
            %group
            plist = 'H5P_DEFAULT';
            gid = H5G.create(fid, strcat(path, '/', obj.name), plist, plist, plist);
            
            %attributes
            tid = H5T.copy('H5T_C_S1');
            sid = H5S.create('H5S_SCALAR');
            pid = H5P.create('H5P_ATTRIBUTE_CREATE');
            aid = H5A.create(gid, 'help', tid, sid, pid);
            H5A.write(aid, 'H5ML_DEFAULT', obj.help);
            H5A.close(aid);
        end
    end
end