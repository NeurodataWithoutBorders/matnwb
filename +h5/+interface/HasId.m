classdef HasId < handle
    %HASID Interface for H5 objects with a representable id
    
    methods (Abstract)
        id = get_id(obj);
    end
    
    methods
        function Identifier = get_type(obj)
            Identifier = H5I.get_type(obj.get_id());
        end
    end
end

