classdef HasSpace < h5.interface.HasId
    %HASSPACE There is H5 space data associated with this object.
    
    methods (Abstract, Access = protected)
        space_id = get_space_id(obj);
    end
    
    methods
        function Space = get_space(obj)
            sid = obj.get_space_id();
            if 0 < H5S.is_simple(sid)
                Space = h5.space.SimpleSpace(sid);
            else
                Space = h5.Space(sid);
            end
        end
    end
end

