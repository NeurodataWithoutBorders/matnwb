classdef HasType < handle
    %HASTYPE There is H5 Type data associated with this object.
    
    methods (Abstract, Access = protected)
        type_id = get_type_id(obj);
    end
end

