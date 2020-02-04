classdef SimpleSpace < h5.Space
    %SIMPLESPACE nd-array space
    
    methods (Static)
        function SimpleSpace = from_hyperslabs(HyperSlabs)
            MSG_ID_CONTEXT = 'NWB:H5:Space:SimpleSpace:FromHyperslabs:';
            assert(isa(HyperSlabs, 'h5.space.Hyperslab'),...
                [MSG_ID_CONTEXT 'InvalidArgument'],...
                '`Slabs` must be an array of h5.space.Hyperslabs.');
            
            SimpleSpace = h5.space.SimpleSpace.create();
            bounds = zeros(1, length(HyperSlabs(1).shape));
            for i = 1:numel(HyperSlabs)
                Slab = HyperSlabs(i);
                assert(Slab.rank == length(bounds),...
                    [MSG_ID_CONTEXT 'InvalidHyperslabRank'],...
                    'All Hyperslab Ranks must match.');
                
                bounds = max([bounds; Slab.bounds], 1);
            end
            SimpleSpace.extents = bounds;
            SimpleSpace.dims = bounds;
        end
        
        function SimpleSpace = create()
            SimpleSpace = h5.space.SimpleSpace(...
                H5S.create(h5.const.SpaceType.Simple.constant));
        end
    end
    
    methods (Static, Access = private)
        function subs = collect_ind2sub(data_size, indices)
            %COLLECT_IND2SUB a variant of IND2SUB that collects the outputs into a
            % matrix array.
            data_size = double(data_size);
            num_dims = length(data_size);
            
            subs = zeros(length(indices), num_dims);
            stride = cumprod(data_size);
            for i = num_dims:-1:2
                leftover = rem(indices - 1, stride(i - 1)) + 1;
                rank_value = (indices - leftover) / stride(i - 1) + 1;
                subs(:, i) = double(rank_value);
                indices = leftover;
            end
            subs(:, 1) = double(indices);
        end
    end
    
    properties (Dependent)
        dims;
        extents;
    end
    
    methods % lifecycle override
        function obj = SimpleSpace(id)
            assert(H5S.get_simple_extent_type(id) == h5.const.SpaceType.Simple.constant,...
                'NWB:H5:SimpleSpace:InvalidArgument',...
                'Provided id is not a Simple Space');
            obj = obj@h5.Space(id);
        end
    end
    
    methods (Access = private)
        function select_with_slabs(obj, Hyperslabs)
            for i = 1:length(Hyperslabs)
                Slab = Hyperslabs(i);
                h5_start = fliplr(Slab.offset);
                h5_stride = fliplr(Slab.stride);
                h5_count = fliplr(Slab.shape);
                H5S.select_hyperslab(obj.id,...
                    'H5S_SELECT_OR', h5_start, h5_stride, h5_count, []);
            end
        end
        
        function select_with_points(obj, points)
            %SELECT_WITH_POINTS selects this space based on coordinates
            % These are assumed to be 1-indexed in MATLAB format.
            % Further conversion to h5 coordinates are made in this
            % function.
            % The precise shape should be a NxM array where N is the
            % number of points you wish to select and M is the number
            % of dimensions in the space.
            
            if isvector(points)
                points = h5.space.SimpleSpace.collect_ind2sub(obj.dims, points);
            end
            h5_coord = rot90(points, -1) - 1; % transpose + fliplr + 0-indexed
            H5S.select_elements(obj.id, 'H5S_SELECT_APPEND', h5_coord);
        end
    end
    
    methods % get/set
        function set.dims(obj, val)
            ERR_MSG_STUB = 'NWB:H5:SimpleSpace:SetDims:';
            assert(isnumeric(val) && ~isempty(val),...
                [ERR_MSG_STUB 'InvalidArgument'],...
                'property `dims` requires a non-empty numeric array');
            
            assert(all(isfinite(val)),...
                [ERR_MSG_STUB 'InfiniteDims'],...
                '`dims` cannot have infinite dimensions.  Set Extents instead.');
            extents = obj.extents;
            
            rank = length(extents);
            assert(rank >= length(val),...
                [ERR_MSG_STUB, 'InvalidRank'],...
                'rank of dims should match rank of extents.');
            
            if rank > length(val)
                newVal = ones(1, rank);
                newVal(1:length(val)) = val;
                val = newVal;
            end
            h5_dims = fliplr(val);
            h5_max_dims = fliplr(extents);
            h5_max_dims(h5_max_dims == Inf) = h5.const.Space.Unlimited.constant;
            H5S.set_extent_simple(obj.id, rank, h5_dims, h5_max_dims);
        end
        
        function dims = get.dims(obj)
            [~, h5_dims, ~] = H5S.get_simple_extent_dims(obj.get_id());
            dims = fliplr(h5_dims);
        end
        
        function set.extents(obj, val)
            ERR_MSG_STUB = 'NWB:H5:SimpleSpace:SetExtents:';
            assert(isnumeric(val) && ~isempty(val),...
                [ERR_MSG_STUB 'InvalidArgument'],...
                'property `extents` requires a non-empty numeric array');
            
            val(isinf(val)) = h5.const.Space.Unlimited.constant;
            
            rank = length(val);
            dims = obj.dims;
            if length(dims) > rank
                warning([ERR_MSG_STUB 'CoerceRank'],...
                    'Decreasing dimension rank.  May lose data.');
                dims = dims(1:rank);
            elseif length(dims) < rank
                newDims = ones(1, rank);
                newDims(1:length(dims)) = dims;
                dims = newDims;
            end
            h5_dims = fliplr(dims);
            h5_max_dims = fliplr(val);
            H5S.set_extent_simple(obj.id, rank, h5_dims, h5_max_dims);
        end
        
        function extents = get.extents(obj)
            [~, ~, h5_maxdims] = H5S.get_simple_extent_dims(obj.id);
            extents = fliplr(h5_maxdims);
            extents(extents == h5.const.Space.Unlimited.constant) = Inf;
        end
    end
    
    methods
        function tf = get_is_select_valid(obj)
            tf = H5S.select_valid(obj.id);
        end
        
        function select_all(obj)
            H5S.select_all(obj.id);
        end
        
        function select_none(obj)
            H5S.select_none(obj.id);
        end
        
        function select(obj, Selections)
            %SELECT sets a union of all provided hyperslab selections.
            % previous selections are unset.
            assert(isa(Hyperslabs, 'h5.space.Hyperslab'),...
                'NWB:H5:Space:InvalidArgument',...
                'hyperslab must be an array of Hyperslab objects.');
            
            obj.select_none(); % reset
            if isa(Selections, 'h5.space.Hyperslab')
                obj.select_with_slabs(Selections);
            elseif isnumeric(Selections)
                obj.select_with_points(Selections);
            else
                error('NWB:H5:Space:Simple:Select:InvalidArgument',...
                    ['Selection should either be a Hyperslab array or '...
                    'multi-dimensional array representing points in space.']);
            end
        end
        
        function Hyperslabs = get_selections(obj)
            nblocks = H5S.get_select_hyper_nblocks(obj.get_id());
            blocklist = H5S.get_select_hyper_blocklist(obj.get_id(), 0, nblocks);
            if isempty(blocklist)
                Hyperslabs = h5.space.Hyperslab.empty;
                return;
            end
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