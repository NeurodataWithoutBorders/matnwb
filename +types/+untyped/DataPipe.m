classdef DataPipe < handle
    %DATAPIPE Special form of Datastub that allows for appending.
    
    properties
        axis; % axis index in MATLAB format indicating which axis to increment.
        offset; % axis offset of dataset to append.  May be used to overwrite data.
        chunkSize; % ideal size of chunks for incremental data appending.
        dataType; % one of float|double|uint8|int8|int16|uint16|int32|uint32|int64|uint64
    end
    
    properties (SetAccess = private)
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
            obj.offset = p.Results.offset;
            obj.axis = p.Results.axis;
            obj.chunkSize = p.Results.chunkSize;
            obj.dataType = p.Results.dataType;
        end
    end
    
    methods % get/set
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
            
            assert(isempty(obj.filename),...
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
            
            assert(isempty(obj.filename),...
                'NWB:Untyped:DataPipe:SetDataType:SettingLocked',...
                ['`dataType` cannot be reset if this datapipe is bound to an '...
                'existing NWB file.']);
            
            obj.dataType = val;
        end
    end
    
    methods
        function append(obj, data)
            assert(isa(data, obj.dataType),...
                'NWB:Untyped:DataPipe:Append:InvalidType',...
                'Data must match dataType')
            
            PLIST = 'H5P_DEFAULT';
            try
                fid = H5F.open(obj.filename);
                did = H5D.open(fid, obj.path);
            catch ME
                rethrow(addCause(ME,...
                    MException(...
                    'NWB:Untyped:DataPipe:ExportRequired',...
                    ['Appending to a dataset requires exporting and re-importing '...
                    'a valid NWB file.'])));
            end
            
            sid = H5D.get_space(did);
            H5S.select_none(sid);
            
            offset_coords = ones(size(obj.max_size));
            offset_coords(obj.axis) = obj.offset;
            
            h5_start = fliplr(offset_coords) - 1;
            h5_stride = fliplr(size(data));
            h5_count = numel(data);
            h5_block = [];
            H5S.select_hyperslab(sid,...
                'H5S_SELECT_SET',...
                h5_start,...
                h5_stride,...
                h5_count,...
                h5_block);
            
            [mem_tid, mem_sid, data] = io.mapData2H5(fid, data, 'forceArray');
            
            H5D.write(did, mem_tid, mem_sid, sid, PLIST, data);
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
            if ~isempty(obj.filename) % all data should've been written before export.
                return;
            end
            
            pid = 'H5P_DEFAULT';
            
            rank = length(obj.maxSize);
            h5_dims = zeros(length(obj.maxSize));
            h5_maxdims = fliplr(obj.maxSize);
            sid = H5S.create_simple(rank, h5_dims, h5_maxdims);
            
            create_pid = H5P.create('H5P_DATASET_CREATE');
            if isempty(obj.chunkSize)
                h5_chunk_dims = fliplr(obj.chunkSize);
            else
                h5_chunk_dims = h5_max_dims;
            end
            H5P.set_chunk(create_pid, h5_chunk_dims);
            tid = io.getBaseType(obj.dataType);
            did = H5D.create(fid, fullpath, tid, sid, pid, create_pid, pid);
            
            H5P.close(create_pid);
            if ~ischar(tid)
                H5T.close(tid);
            end
            H5S.close(sid);
            H5D.close(did);
        end
    end
end

