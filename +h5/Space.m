classdef Space < h5.interface.HasId
    %SPACE HDF Space
    
    methods (Static)
        function Space = create(SpaceType)
            assert(isa(SpaceType, 'h5.space.SpaceType'),...
                'NWB:H5:Space:InvalidArgument',...
                'Space type should be a type h5.space.SpaceType');
            Space = h5.Space(H5S.create(SpaceType.string));
        end
    end
    
    properties (SetAccess = private, Dependent)
        spaceType;
    end
    
    properties (Access = private)
        id;
    end
    
    methods % lifecycle
        function obj = Space(id)
            obj.id = id;
        end
        
        function delete(obj)
            H5S.close(obj.id);
        end
    end
    
    methods % get/set
        function SpaceType = get.spaceType(obj)
            SpaceType = h5.space.SpaceType();
        end
    end
    
    methods
        function select(obj, hyperslabs)
            assert(obj.spaceType == h5.space.SpaceType.Simple,...
                'NWB:H5:Space:InvalidSpaceType',...
                'To set hyperslabs, create a Simple Space.');
            assert(isa(val, 'h5.space.Hyperslab'),...
                'NWB:H5:Space:InvalidArgument',...
                'hyperslab must be an array of Hyperslab objects.');
        end
        
        function resize(obj, extents)
            assert(obj.spaceType == h5.space.SpaceType.Simple,...
                'NWB:H5:Space:InvalidSpaceType',...
                'To resize extents, create a Simple Space.');
        end
    end
    
    methods % HasId
        function id = get_id(obj)
            id = obj.id;
        end
    end
end

