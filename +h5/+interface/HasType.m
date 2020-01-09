classdef HasType < handle
    %HASTYPE There is H5 Type data associated with this object.
    
    methods (Abstract, Access = protected)
        type_id = get_type_id(obj);
    end
    
    methods
        function Type = get_type(obj)
            Type = h5.Type(obj.get_type_id());
        end
    end
end