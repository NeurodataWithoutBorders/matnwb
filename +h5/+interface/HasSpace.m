classdef HasSpace < h5.interface.HasId
    %HASSPACE There is H5 space data associated with this object.
    
    methods (Abstract, Access = protected)
        space_id = get_space_id(obj);
    end
    
    methods
        function Space = get_space(obj)
            Space = h5.Space(obj.get_space_id());
        end
    end
end

