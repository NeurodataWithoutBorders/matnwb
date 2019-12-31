classdef DataPipe < handle
    %DATAPIPE Special form of Datastub that allows for appending.
    
    properties
        axis; % axis index in MATLAB format indicating which axis to increment.
        offset; % axis offset of dataset to append.  May be used to overwrite data.
        chunkSize; % ideal size of chunks for incremental data appending.
        dataType; % one of float|double|uint8|int8|int16|uint16|int32|uint32|int64|uint64
    end
    
    properties (SetAccess = private)
        isBound; % is associated with a filename and path
        filename;
        path;
        maxSize; % maximum dimension size
    end
    
    methods % lifecycle
        function obj = DataPipe(maxSize, varargin)
            obj.maxSize = maxSize;
            
            p = inputParser;
            p.addParameter('filename', '');
            p.addParameter('path', '');
            p.addParameter('offset', 1);
            p.addParameter('axis', 1);
            p.addParameter('chunkSize', []);
            p.addParameter('dataType', 'uint8');
            p.parse(varargin{:});
            
            obj.filename = p.Results.filename;
            obj.path = p.Results.path;
            obj.axis = p.Results.axis;
            obj.offset = p.Results.offset;
            obj.chunkSize = p.Results.chunkSize;
            obj.dataType = p.Results.dataType;
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
            assert(isscalar(val) && isnumeric(val),...
                'NWB:Untyped:DataPipe:SetAxis:InvalidType',...
                'Axis should be an axis index within max_size bounds.');
            val = ceil(val);
            
            assert(val > 0 && length(obj.maxSize) >= val,...
                'NWB:Untyped:DataPipe:SetAxis:InvalidAxisRange',...
                '`axis` should be within `max_size`''s rank (got %d)', val);
            obj.axis = val;
        end
        
        function set.offset(obj, val)
            assert(isscalar(val) && isnumeric(val) && val > 0,...
                'NWB:Untyped:DataPipe:SetOffset:InvalidType',...
                'Offset should be a nonzero scalar indicating axis offset.');
            val = ceil(val);
            
            assert(obj.maxSize(obj.axis) >= val,...
                'NWB:Untyped:DataPipe:SetOffset:InvalidOffsetRange',...
                'Offset should be within maxSize bound %d (got %d)',...
                obj.maxSize(obj.axis),...
                val);
            obj.offset = val;
        end
        
        function set.chunkSize(obj, val)
            assert(isnumeric(val),...
                'NWB:Untyped:DataPipe:SetChunkSize:InvalidType',...
                '`chunkSize` must be a numeric vector');
            val = ceil(val);
            
            assert(length(val) <= length(obj.maxSize),...
                'NWB:Untyped:DataPipe:SetChunkSize:InvalidChunkRank',...
                '`chunkSize` rank should match `maxSize` rank');
            newVal = ones(size(obj.maxSize));
            newVal(1:length(val)) = val;
            val = newVal;
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
            assert(ischar(val),...
                'NWB:Untyped:DataPipe:SetDataType:InvalidType',...
                '`dataType` must be a string');
            SUPPORTED_DATATYPES = {...
                'float', 'double', 'uint8', 'int8', 'uint16', 'int16', 'uint32',...
                'int32', 'uint64', 'int64'
                };
            assert(any(strcmp(val, SUPPORTED_DATATYPES)),...
                'NWB:Untyped:DataPipe:SetDataType:InvalidType',...
                '`dataType` must be one of the supported datatypes `%s`',...
                strjoin(SUPPORTED_DATATYPES, '|'));
            
            assert(~obj.isBound,...
                'NWB:Untyped:DataPipe:SetDataType:SettingLocked',...
                ['`dataType` cannot be reset if this datapipe is bound to an '...
                'existing NWB file.']);
            
            obj.dataType = val;
        end
    end
    
    methods
        function size = get_size(obj)
            assert(obj.isBound,...
                'NWB:Untyped:DataPipe:GetSize:NoAvailableSize',...
                ['DataPipe must first be bound to a valid hdf5 filename and path to '...
                'query its current dimensions.']);
            
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
            assert(isa(data, obj.dataType),...
                'NWB:Untyped:DataPipe:Append:InvalidType',...
                'Data must match dataType')
            assert(obj.isBound,...
                'NWB:Untyped:DataPipe:ExportRequired',...
                ['Appending to a dataset requires exporting and re-importing '...
                    'a valid NWB file.']);
            
            if isempty(data)
                return;
            end
            
            default_pid = 'H5P_DEFAULT';
            
            fid = H5F.open(obj.filename, 'H5F_ACC_RDWR', default_pid);
            did = H5D.open(fid, obj.path, default_pid);
            
            rank = length(obj.maxSize);
            stride_coords = ones(1, rank);
            stride_coords(1:length(size(data))) = size(data);
            new_extents = obj.maxSize;
            new_extents(obj.axis) = obj.offset + stride_coords(obj.axis) - 1;
            h5_extents = fliplr(new_extents);
            H5D.set_extent(did, h5_extents);
                   
            sid = H5D.get_space(did);
            H5S.select_none(sid);

            offset_coords = ones(1, rank);
            offset_coords(obj.axis) = obj.offset;
            
            h5_start = fliplr(offset_coords) - 1;
            h5_stride = [];
            h5_count = fliplr(stride_coords);
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
            
            obj.offset = obj.offset + size(data, obj.axis);
        end
        
        function refs = export(obj, fid, fullpath, refs)
            if obj.isBound
                return;
            end
            
            default_pid = 'H5P_DEFAULT';
            
            tid = io.getBaseType(obj.dataType);
            
            rank = length(obj.maxSize);
            h5_dims = zeros(1, rank);
            h5_maxdims = fliplr(obj.maxSize);
            h5_maxdims(h5_maxdims == Inf) = H5ML.get_constant_value('H5S_UNLIMITED');
            sid = H5S.create_simple(rank, h5_dims, h5_maxdims);
            
            lcpl = default_pid;

            dcpl = H5P.create('H5P_DATASET_CREATE');
            if isempty(obj.chunkSize)
                h5_chunk_dims = h5_maxdims;
            else
                h5_chunk_dims = fliplr(obj.chunkSize);
            end
            H5P.set_chunk(dcpl, h5_chunk_dims);
            
            dapl = default_pid;
            
            did = H5D.create(fid, fullpath, tid, sid, lcpl, dcpl, dapl);
            
            H5P.close(dcpl);
            H5S.close(sid);
            if ~ischar(tid)
                H5T.close(tid);
            end            
            H5D.close(did);
            
            % bind to this file.
            obj.filename = H5F.get_name(fid);
            obj.path = fullpath;
        end
    end
end

