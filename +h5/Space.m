classdef Space < h5.interface.HasId
    %SPACE HDF Space
    
    methods (Static)
        function Space = from_matlab(dataSize, matlabType, varargin)
            ERR_MSG_STUB = 'NWB:H5:Space:FromMatlab:';
            
            assert(isnumeric(dataSize) && ~isempty(dataSize),...
                [ERR_MSG_STUB 'InvalidArguments'],...
                '`dataSize` must be from size(data)');
            assert(ischar(matlabType),...
                [ERR_MSG_STUB 'InvalidArguments'],...
                'Type must be from class(data).');
            
            p = inputParser;
            p.addParameter('spacetype', h5.const.SpaceType.empty,...
                @(s)assert(isa(s, 'h5.const.SpaceType'),...
                [ERR_MSG_STUB 'InvalidKeywordArgument'],...
                '`spacetype` must be a h5.const.SpaceType'));
            p.parse(varargin{:});
            SpaceType = p.Results.spacetype;
            
            if isempty(SpaceType)
                SpaceType = derive_space_type(dataSize, matlabType);
            end
            
            Space = h5.Space.create(SpaceType);
            
            if ~isa(Space, 'h5.space.SimpleSpace')
                return;
            end
            
            if strcmp('char', matlabType)
                dataSize(2) = 1;
            end
            
            Space.extents = dataSize;
            Space.dims = dataSize;
            
            function SpaceType = derive_space_type(dataSize, matlabType)
                if any(dataSize == 0)
                    SpaceType = h5.const.SpaceType.Null;
                elseif all(dataSize == 1) ||...
                        (strcmp('char', matlabType)...
                        && all(dataSize([1, 3:length(dataSize)]) == 1))
                    SpaceType = h5.const.SpaceType.Scalar;
                else
                    SpaceType = h5.const.SpaceType.Simple;
                end
            end
        end
        
        function Space = create(SpaceType)
            assert(isa(SpaceType, 'h5.const.SpaceType'),...
                'NWB:H5:Space:InvalidArgument',...
                'Space type should be a type h5.const.SpaceType');
            
            if SpaceType == h5.const.SpaceType.Simple
                Space = h5.space.SimpleSpace.create();
            else
                Space = h5.Space(H5S.create(SpaceType.constant));
            end
        end
    end
    
    properties (SetAccess = private, Dependent)
        spaceType;
    end
    
    properties (Access = protected)
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
            SpaceType = h5.interface.IsConstant.from_constant(...
                'h5.const.SpaceType',...
                H5S.get_simple_extent_type(obj.id));
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

