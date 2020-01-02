classdef NullSpace < h5.Space
    %NULLSPACE Empty Space
    
    methods % lifecycle override
        function obj = NullSpace()
            obj = obj@h5.Space(H5S.create(h5.space.SpaceType.Null.get_id()));
        end
    end
end