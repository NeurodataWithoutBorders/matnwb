classdef NWBContainer
    properties %name and typename
        name;
    end
    
    properties %extensions
        attributes = struct();
        datasets = struct();
        groups = [];
        softlinks = struct();
        externlinks = struct();
    end
    
    methods
        %g_obj being one or MORE group objects
        function obj = NWBContainer(g_obj, filename)
            if nargin ~= 0
                obj(length(g_obj)) = types.NWBContainer;
                for i=1:length(g_obj)
                    obj(i).name = g_obj(i).Name;
                    obj(i).attributes = g_obj(i).Attributes;
                    obj(i).datasets = g_obj(i).Datasets;
                    if ~isempty(obj(i).datasets)
                        for j=1:length(obj(i).datasets)
                            nm = obj(i).datasets(j).Name;
                            ds_path = strcat(obj(i).name, '/', nm);
                            obj(i).datasets(j).Values = h5read(filename, ds_path);
                        end
                    end
                    if ~isempty(g_obj(i).Groups)
                        obj(i).groups = types.NWBContainer(g_obj(i).Groups, filename);
                    end
                    
                    %softlinks and external links
                    if ~isempty(g_obj(i).Links)
                        links = g_obj(i).Links;
                        for j=1:length(links)
                            link = links(j);
                            if strcmp(link.Type, 'soft link')
                                obj(i).softlinks.(link.Name) = link.Value;
                            else
                                obj(i).externlinks.(link.Name) = link.Value;
                            end
                        end
                    end
                end
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