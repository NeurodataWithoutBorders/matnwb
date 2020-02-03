classdef ScalarSpace < h5.Space
    %SCALARSPACE Space scalar value
    
    methods (Static)
        function ScalarSpace = create()
            ScalarSpace = h5.space.ScalarSpace(H5S.create(h5.const.SpaceType.Scalar.constant));
        end
    end
    
    methods % lifecycle override
        function obj = ScalarSpace(id)
            assert(H5S.get_simple_extent_type(id) == h5.const.SpaceType.Scalar.constant,...
                'NWB:H5:ScalarSpace:InvalidArgument',...
                'Provided ID is not a Scalar Space');
            obj = obj@h5.Space(id);
        end
    end
end

