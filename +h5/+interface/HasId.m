classdef HasId < handle
    %HASID Interface for H5 objects with a representable id
    
    methods (Abstract)
        id = get_id(obj);
    end
    
    methods
        function id_type = get_id_type(obj)
            id_type = H5I.get_type(obj.get_id());
        end
        
        function File = get_file(obj)
            File = h5.File(H5I.get_file_id(obj.get_id()));
        end
    end
end

