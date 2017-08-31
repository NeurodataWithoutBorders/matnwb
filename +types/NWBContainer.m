classdef NWBContainer
    properties %name and typename
        name;
    end
    
    properties %extensions
        attributes = struct([]);
        datasets = struct([]);
        groups = struct([]);
        softlinks = struct([]);
        externlinks = struct([]);
    end
    
    methods
        function obj = NWBContainer(g_obj)
            obj.name = g_obj.Name;
            obj.attributes = g_obj.Attributes;
            obj.datasets = g_obj.Datasets;
            
            for i=1:length(g_obj.Groups)
                group = g_obj.Groups(i);
                obj.groups.(group.Name) = NWBContainer(group);
            end
        end
        
        function hdf_obj = export(obj, loc_id)
            %group
            gid = h5helper.createGroup(loc_id, strcat('/', obj.name));
            
            %attributes
            tid = h5helper.getString();
            sid = H5S.create('H5S_SCALAR');
            pid = H5P.create('H5P_ATTRIBUTE_CREATE');
            aid = H5A.create(loc_id, 'help', tid, sid, pid);
            H5A.write(aid, 'H5ML_DEFAULT', data);
            H5A.close(aid);
            
            %extensions
            for i=1:length(groups)
            end
        end
    end
end