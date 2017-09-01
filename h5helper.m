classdef h5helper
    methods(Static)
        %get variable string type
        function id = getStringId()
            id = H5T.copy('H5T_C_S1');
            H5T.set_size(id, 'H5T_VARIABLE');
        end
        function id = getUint8Id()
            id = getNumericId('UINT8');
        end
        function id = getFloat32Id()
            id = getNumericId('FLOAT');
        end
        function id = getFloat64Id()
            id = getNumericId('DOUBLE');
        end
        function id = getInt32Id()
            id = getNumericId('INT32');
        end
        function id = getUint16Id()
            id = getNumericId('UINT16');
        end
        function id = getInt8Id()
            id = getNumericId('INT8');
        end
        function id = getInt64Id()
            id = getNumericId('INT64');
        end
        function id = getNumericId(suffix)
            id = H5T.copy(strcat('H5T_NATIVE_',suffix));
        end
        
        function gid = createGroup(loc_id, name)
            plist = 'H5P_DEFAULT';
            gid = H5G.create(loc_id, name, plist, plist, plist);
        end
        
        function attr_id = createAttr(loc_id, name, type_id, spacename)
            sid = H5S.create(spacename);
            pid = H5P.create('H5P_ATTRIBUTE_CREATE');
            attr_id = H5A.create(loc_id, name, type_id, sid, pid);
            H5S.close(sid);
        end
        
        function id = writeAttr(loc_id, name, data)
            pid = H5P.create('H5P_ATTRIBUTE_CREATE');
            if strcmp(class(data), 'string') || strcmp(class(data), 'char')
                tid = h5helper.getStringId();
                sid = H5S.create('H5S_SCALAR');
                a_id = H5A.create(loc_id, name, tid, sid, pid);
            else
                
            end
        end
        
        function did = createDataset(loc_id, name, type_id, dimensions)
            sid = H5S.create_simple(length(dimensions), dimensions, dimensions);
            did = H5D.create(loc_id, name, type_id, sid, 'H5P_DEFAULT');
        end
        
        %converts HDF5 groups into NWBContainers
        function group_struct = importH5Groups(group_array)
            group_struct = struct();
            for i=1:length(group_array)
                g = group_array(i);
                %hdf5 saves the entire path as Name
                %so parse out the true name on import
                [~, filename, ~] = fileparts(g.Name);
                group_struct.(filename) = types.NWBContainer(g);
            end
        end
    end
end