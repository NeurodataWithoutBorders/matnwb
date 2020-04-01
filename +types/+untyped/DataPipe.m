classdef DataPipe < handle
    %DATAPIPE Special form of Datastub that allows for appending.
    % Current limitations: DataPipe currently only supports the types
    % represented by dataType.  No strings, or references are allowed with
    % DataPipes.
    
    methods (Static)
        function obj = fromFile(filename, path)
            fid = H5F.open(filename);
            did = H5D.open(fid, path);
            sid = H5D.get_space(did);
            pid = H5D.get_create_plist(did);
            tid = H5D.get_type(did);
            
            [numdims, h5_dims, h5_maxdims] = H5S.get_simple_extent_dims(sid);
            current_size = fliplr(h5_dims);
            max_size = fliplr(h5_maxdims);
            if 1 == numdims
                current_size = [current_size 1];
                max_size = [max_size 1];
            end
            [~, h5_chunk_dims] = H5P.get_chunk(pid);
            
            deflate_filter = H5ML.get_constant_value('H5Z_FILTER_DEFLATE');
            level = -1;
            for i = 0:(H5P.get_nfilters(pid) - 1)
                [filter, ~, cd_values, ~, ~] = H5P.get_filter(pid, i);
                if filter == deflate_filter
                    level = cd_values;
                    break;
                end
            end
            
            obj = types.untyped.DataPipe(max_size, 1);
            obj.offset = current_size(obj.axis);
            obj.chunkSize = fliplr(h5_chunk_dims);
            obj.compressionLevel = level;
            obj.dataType = io.getMatType(tid);
            obj.filename = filename;
            obj.path = path;
            
            H5T.close(tid);
            H5P.close(pid);
            H5S.close(sid);
            H5D.close(did);
            H5F.close(fid);
        end
        
        function obj = fromData(data, axis)
            if nargin < 2
                axis = 1;
            end
            maxSize = size(data);
            maxSize(axis) = Inf;
            obj = types.untyped.DataPipe(maxSize, axis);
            obj.data = data;
        end
    end
    
    properties
        axis = 1; % indices indicating which dimension to append data to.

        % offset of dataset to append.  May be used to overwrite data.
        offset = 0;
        
        chunkSize = []; % ideal size of chunks for incremental data appending.
        
        % DEFLATE level for the dataset. -1 for disabled compression
        compressionLevel = -1;
        
        % one of float|double|uint8|int8|int16|uint16|int32|uint32|int64|uint64
        dataType = 'double';
        
        data = []; % Writable data
    end
    
    properties (SetAccess = private, Dependent)
        isBound; % this datapipe is dependent on an existing dataset.
    end
    
    properties (SetAccess = private)
        filename = '';
        path = '';
        maxSize; % maximum dimension size
    end
    
    properties (Access = private, Constant)
        SUPPORTED_DATATYPES = {...
            'float', 'double', 'uint8', 'int8', 'uint16', 'int16',...
            'uint32', 'int32', 'uint64', 'int64'
            };
    end
    
    methods % lifecycle
        function obj = DataPipe(maxSize, axis)
            obj.maxSize = maxSize;
            obj.axis = axis;
        end
    end
    
    methods % get/set
        function tf = get.isBound(obj)
            try
                fid = H5F.open(obj.filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
                did = H5D.open(fid, obj.path, 'H5P_DEFAULT');
                
                tf = true;
            catch
                tf = false;
            end
            
            if 1 == exist('fid', 'var')
                H5F.close(fid);
            end
            
            if 1 == exist('did', 'var')
                H5D.close(did);
            end
        end
        
        function set.axis(obj, val)
            assert(isnumeric(val)...
                && isscalar(val)...
                && val > 0 ...
                && val <= length(obj.maxSize),...
                'NWB:Untyped:DataPipe:SetAxis:InvalidArgument',...
                'Axis must be scalar index in range of maxSize rank.');
            obj.axis = ceil(val);
        end
        
        function set.offset(obj, val)
            assert(isnumeric(val) && isscalar(val) && val >= 0,...
                'NWB:Untyped:DataPipe:SetOffset:InvalidType',...
                ['Offset should be a non-negative number indicating axis '...
                'offset.']);
            obj.offset = ceil(val);
        end
        
        function set.chunkSize(obj, val)
            assert(isnumeric(val) && length(val) == length(obj.maxSize),...
                'NWB:Untyped:DataPipe:SetChunkSize:InvalidType',...
                '`chunkSize` must be a numeric vector of size %d',...
                length(obj.maxSize));
            val = ceil(val);
            assert(all(val <= obj.maxSize),...
                'NWB:Untyped:DataPipe:SetChunkSize:InvalidChunkSize',...
                '`chunkSize` must be within `maxSize` bounds');
            assert(~obj.isBound,...
                'NWB:Untyped:DataPipe:SetChunkSize:SettingLocked',...
                ['`chunkSize` cannot be reset if this datapipe is bound to an '...
                'existing NWB file.']);
            
            obj.chunkSize = val;
        end
        
        function set.dataType(obj, val)
            import types.untyped.DataPipe;
            
            assert(ischar(val),...
                'NWB:Untyped:DataPipe:SetDataType:InvalidType',...
                '`dataType` must be a string');
            
            assert(any(strcmp(val, DataPipe.SUPPORTED_DATATYPES)),...
                'NWB:Untyped:DataPipe:SetDataType:InvalidType',...
                '`dataType` must be one of the supported datatypes `%s`',...
                strjoin(DataPipe.SUPPORTED_DATATYPES, '|'));
            
            assert(~obj.isBound,...
                'NWB:Untyped:DataPipe:SetDataType:SettingLocked',...
                ['`dataType` cannot be reset if this datapipe is bound to an '...
                'existing NWB file.']);
            assert(isempty(obj.data) || strcmp(class(obj.data), val),...
                'NWB:Untyped:DataPipe:SetDataType:CannotSet',...
                ['`dataType` cannot be reset if data has been queued.  '...
                'To change the datatype, change the queued data''s type.']);
            
            obj.dataType = val;
        end
        
        function set.data(obj, val)
            assert(~obj.isBound,...
                'NWB:Untyped:DataPipe:SetData:SettingLocked',...
                ['`data` cannot be set if this DataPipe is bound to an '...
                'existing NWB file']);
            obj.data = val;
            obj.dataType = class(val);
        end
        
        function set.compressionLevel(obj, val)
            assert(~obj.isBound,...
                'NWB:Untyped:DataPipe:SetCompressionLevel:SettingLocked',...
                ['`compressionLevel` can only be set if DataPipe has not '...
                'yet been bound to a NWBFile.']);
            
            assert(isscalar(val) && isnumeric(val),...
                'NWB:Untyped:DataPipe:SetCompressionLevel:InvalidType',...
                '`compressionLevel` must be a scalar numeric value.');
            val = ceil(val);
            assert(val >= -1 && val <= 9,...
                'NWB:Untyped:DataPipe:SetCompressionLevel:OutOfRange',...
                '`compressionLevel` range is [0, 9] or -1 for off.', val);
            
            obj.compressionLevel = val;
        end
    end
    
    methods
        function size = get_size(obj)
            assert(obj.isBound,...
                'NWB:Untyped:DataPipe:GetSize:NoAvailableSize',...
                ['DataPipe must first be bound to a valid hdf5 filename and '...
                'path to query its current dimensions.']);
            
            fid = H5F.open(obj.filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
            did = H5D.open(fid, obj.path, 'H5P_DEFAULT');
            sid = H5D.get_space(did);
            [~, h5_dims, ~] = H5S.get_simple_extent_dims(sid);
            size = fliplr(h5_dims);
            H5S.close(sid);
            H5D.close(did);
            H5F.close(fid);
        end
        
        function append(obj, data)
            if isempty(data)
                return;
            end
            
            assert(obj.isBound,...
                'NWB:Untyped:DataPipe:ExportRequired',...
                ['Appending to a dataset requires exporting and re-importing '...
                'a valid NWB file.']);

            rank = length(obj.maxSize);
            data_size = size(data);
            if length(data_size) < rank
                new_coords = ones(1, rank);
                new_coords(1:length(data_size)) = data_size;
                data_size = new_coords;
            elseif length(data_size) > rank
                if ~all(data_size(rank+1:end) == 1)
                    warning('NWB:Types:Untyped:DataPipe:InvalidRank',...
                    ['Expected rank %d not expected for data of size %s.  '...
                    'Data may be lost on write.'],...
                    rank, mat2str(size(data_size)));
                end
                data_size = data_size(1:rank);
            end
            
            default_pid = 'H5P_DEFAULT';
            fid = H5F.open(obj.filename, 'H5F_ACC_RDWR', default_pid);
            did = H5D.open(fid, obj.path, default_pid);
            sid = H5D.get_space(did);
            [~, h5_dims, ~] = H5S.get_simple_extent_dims(sid);
            new_extents = data_size;
            if all(0 < h5_dims)
                current_size = fliplr(h5_dims);
                new_extents(obj.axis) = new_extents(obj.axis)...
                    + current_size(obj.axis);
            end
            assert(all(obj.maxSize >= new_extents),...
                'NWB:Types:Untyped:DataPipe:InvalidSize',...
                'Data size cannot exceed maximum allocated size.');
            sizes_ind = 1:length(obj.maxSize);
            non_axes_mask = (sizes_ind ~= obj.axis) & ~isinf(obj.maxSize);
            assert(all(...
                obj.maxSize(non_axes_mask) == new_extents(non_axes_mask)),...
                'NWB:Types:Untyped:DataPipe:InvalidSize',...
                'Non-axis data size should match maxSize');
            H5D.set_extent(did, fliplr(new_extents));

            H5S.select_none(sid);
            start_indices = zeros(1, rank);
            start_indices(obj.axis) = obj.offset;
            
            h5_start = fliplr(start_indices);
            h5_stride = [];
            h5_count = fliplr(data_size);
            h5_block = [];
            H5S.select_hyperslab(sid,...
                'H5S_SELECT_OR',...
                h5_start,...
                h5_stride,...
                h5_count,...
                h5_block);
            
            [mem_tid, mem_sid, data] = io.mapData2H5(fid, data, 'forceArray');
            H5S.set_extent_simple(mem_sid, rank, h5_count, h5_count);
            
            H5D.write(did, mem_tid, mem_sid, sid, default_pid, data);
            H5S.close(mem_sid);
            if ~ischar(mem_tid)
                H5T.close(mem_tid);
            end
            H5S.close(sid);
            H5D.close(did);
            H5F.close(fid);
            
            obj.offset = obj.offset + data_size(obj.axis);
        end
        
        function refs = export(obj, fid, fullpath, refs)
            if obj.isBound
                return;
            end
            
            default_pid = 'H5P_DEFAULT';
            tid = io.getBaseType(obj.dataType);
            
            rank = length(obj.maxSize);
            h5_dims = zeros(1, rank);
            h5_rank = find(obj.maxSize == 1);
            if isempty(h5_rank)
                h5_rank = rank;
            end
            h5_maxdims = fliplr(obj.maxSize(1:h5_rank));
            h5_unlimited = H5ML.get_constant_value('H5S_UNLIMITED');
            h5_maxdims(isinf(h5_maxdims)) = h5_unlimited;
            sid = H5S.create_simple(rank, h5_dims, h5_maxdims);
            
            lcpl = default_pid;
            
            dcpl = H5P.create('H5P_DATASET_CREATE');
            if isempty(obj.chunkSize)
                obj.chunkSize =...
                    types.untyped.datapipe.guessChunkSize(obj.maxSize);
            end
            H5P.set_chunk(dcpl, fliplr(obj.chunkSize));
            
            if obj.compressionLevel ~= -1
                H5P.set_deflate(dcpl, obj.compressionLevel);
            end
            
            dapl = default_pid;
            
            did = H5D.create(fid, fullpath, tid, sid, lcpl, dcpl, dapl);
            
            H5P.close(dcpl);
            H5S.close(sid);
            if ~ischar(tid)
                H5T.close(tid);
            end
            H5D.close(did);
            
            data = obj.data;
            obj.data = cast([], obj.dataType);
            
            % bind to this file.
            obj.filename = H5F.get_name(fid);
            obj.path = fullpath;
            
            obj.append(data);
        end
    end
end

