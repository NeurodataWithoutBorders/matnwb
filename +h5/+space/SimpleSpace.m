classdef SimpleSpace < h5.Space
    %SIMPLESPACE nd-array space
    
    methods (Static)
        function SimpleSpace = create()
            SimpleSpace = h5.space.SimpleSpace(...
                H5S.create(h5.space.SpaceType.Simple.constant));
        end
    end
    
    properties (Dependent)
        dims;
        extents;
    end
    
    methods % lifecycle override
        function obj = SimpleSpace(id)
            assert(H5S.get_simple_extent_type(id) == h5.space.SpaceType.Simple.constant,...
                'NWB:H5:SimpleSpace:InvalidArgument',...
                'Provided id is not a Simple Space');
            obj = obj@h5.Space(id);
        end
    end
    
    methods % get/set
        function set.dims(obj, val)
            ERR_MSG_STUB = 'NWB:H5:SimpleSpace:SetDims:';
            assert(isnumeric(val) && ~isempty(val),...
                'NWB:H5:SimpleSpace:SetDims:InvalidArgument',...
                'property `dims` requires a non-empty numeric array');
            
            assert(all(isfinite(val)),...
                'NWB:H5:SimpleSpace:SetDims:InfiniteDims',...
                '`dims` cannot have infinite dimensions.  Set Extents instead.');
            extents = obj.extents;
            
            assert(length(extents) >= val,...
                [ERR_MSG_STUB, 'InvalidRank'
            H5S.set_extent_simple(obj.id, );
        end
        
        function dims = get.dims(obj)
            [~, h5_dims, ~] = H5S.get_simple_extent_dims(obj.get_id());
            dims = fliplr(h5_dims);
        end
        
        function set.extents(obj, val)
            assert(isnumeric(val) && ~isempty(val),...
                'NWB:H5:SimpleSpace:SetExtents:InvalidArgument',...
                'property `extents` requires a non-empty numeric array');
            
            val(isinf(val)) = h5.const.Space.Unlimited;
            
            H5S.set_extent_simple(obj.id, length(val));
        end
        
        function extents = get.extents(obj)
            [~, ~, h5_maxdims] = H5S.get_simple_extent_dims(obj.id);
            extents = fliplr(h5_maxdims);
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
            
            H5S.select_none(obj.get_id()); % reset
            for i = 1:length(Hyperslabs)
                Slab = Hyperslabs(i);
                h5_start = fliplr(Slab.offset);
                h5_stride = fliplr(Slab.stride);
                h5_count = fliplr(Slab.shape);
                H5S.select_hyperslab(obj.id,...
                    'H5S_SELECT_OR', h5_start, h5_stride, h5_count, []);
            end
        end
        
        function Hyperslabs = get_selections(obj)
            nblocks = H5S.get_select_hyper_nblocks(obj.get_id());
            blocklist = H5S.get_select_hyper_blocklist(obj.get_id(), 0, nblocks);
            %a hyperslab in h5 format consists of two vectors of some rank indicating
            % start and end corners (assuming start < end from center)
            % illustrated here with a 3-dimensional dataset ordered by major order:
            %        start1 end1 start2 end2
            %  rank    1     x     x     x
            %          2     x     x     x
            %          3     x     x     x
            
            % convert C-style to Matlab-style ordering and 1-based indexing.
            blocklist = flipud(blocklist) + 1;
            Hyperslabs = h5.space.Hyperslab.empty(nblocks, 0);
            for i = 1:nblocks
                i_blocklist = 2 * (i - 1) + 1;
                startCoord = blocklist(:, i_blocklist);
                endCoord = blocklist(:, i_blocklist + 1);
                Hyperslabs(i) = h5.space.Hyperslab.from_h5(startCoord, endCoord);
            end
        end
    end
end

