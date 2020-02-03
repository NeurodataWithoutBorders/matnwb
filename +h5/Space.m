classdef Space < h5.interface.HasId
    %SPACE HDF Space
    
    methods (Static)
        function Space = create(SpaceType)
            assert(isa(SpaceType, 'h5.space.SpaceType'),...
                'NWB:H5:Space:InvalidArgument',...
                'Space type should be a type h5.space.SpaceType');
            
            switch SpaceType
                case h5.space.SpaceType.Scalar
                    Space = h5.space.ScalarSpace();
                case h5.space.SpaceType.Simple
                    Space = h5.space.SimpleSpace();
                case h5.space.SpaceType.Null
                    Space = h5.space.NullSpace();
            end
        end
    end
    
    properties (SetAccess = private, Dependent)
        spaceType;
    end
    
    properties (Access = protected)
        id;
    end
    
    methods (Access = protected) % lifecycle
        function obj = Space(id)
            obj.id = id;
        end
    end
    
    methods % lifecycle
        function delete(obj)
            H5S.close(obj.id);
        end
    end
    
    methods % get/set
        function SpaceType = get.spaceType(obj)
            SpaceType = H5S.get_simple_extent_type(obj.id);
        end
    end
    
    methods
        function NewSpace = copy(obj)
            NewSpace = h5.Space(H5S.copy(obj.id));
        end
    end

    methods % HasId
        function id = get_id(obj)
            id = obj.id;
        end
    end
end

