classdef NullSpace < h5.Space
    %NULLSPACE Empty Space
    
    methods (Static)
        function NullSpace = create()
            NullSpace = h5.space.NullSpace(H5S.create(h5.const.SpaceType.Null.constant));
        end
    end
    
    methods % lifecycle override
        function obj = NullSpace(id)
            assert(H5S.get_simple_extent_type(id) == h5.const.SpaceType.Null.constant,...
                'NWB:H5:NullSpace:InvalidArgument',...
                'Provided id is not a Null Space ID');
            obj = obj@h5.Space(id);
        end
    end
end