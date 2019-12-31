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
        function select(obj, Hyperslabs)
            %SELECT sets a union of all provided hyperslab selections.
            % previous selections are unset.
            
            assert(obj.spaceType == h5.space.SpaceType.Simple,...
                'NWB:H5:Space:InvalidSpaceType',...
                'To set hyperslabs, create a Simple Space.');
            assert(isa(Hyperslabs, 'h5.space.Hyperslab'),...
                'NWB:H5:Space:InvalidArgument',...
                'hyperslab must be an array of Hyperslab objects.');
            
            H5S.select_none(obj.id); % reset
            for i = 1:length(Hyperslabs)
                Slab = Hyperslabs(i);
                H5S.select_hyperslab(obj.id,...
                    'H5S_SELECT_OR', Slab.start, Slab.stride, Slab.count, []);
            end
        end
        
        function Hyperslabs = get_selections(obj)
            assert(h5.space.Constants.HyperSlabSelection == H5S.get_select_type(obj.id),...
                'NWB:H5:Space:InvalidSelectionMode',...
                'Selection mode is not in Hyperslab Selection Mode!');
            
            nblocks = H5S.get_select_hyper_nblocks(obj.id);
            blocklist = H5S.get_select_hyper_blocklist(obj.id, 0, nblocks);
            
            region = rot90(blocklist, -1); % transpose + fliplr
            region = mat2cell(region, ones(size(region,1)/2,1)+1);
            
            for i = 1:length(region)
                
            end
        end
    end
    
    methods % HasId
        function id = get_id(obj)
            id = obj.id;
        end
    end
end

