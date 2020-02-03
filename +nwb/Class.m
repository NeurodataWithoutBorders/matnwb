classdef Class < matlab.mixin.Heterogeneous
    %CLASS Represents a NWB class that can be writable to a file.
    
    methods (Abstract)
        Props = get_properties(obj);
        name = get_name(obj);
        Parent = get_parent(obj);
    end
    
    methods % Writable
        function write(obj, file_id)
            
        end
    end
end