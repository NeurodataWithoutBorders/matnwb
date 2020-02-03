classdef ScalarSpace < h5.Space
    %SCALARSPACE Space scalar value
    
    methods % lifecycle override
        function obj = ScalarSpace()
            obj = obj@h5.Space(H5S.create(h5.space.SpaceType.Scalar.get_id()));
        end
    end
end

