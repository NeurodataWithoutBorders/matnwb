classdef DataPipe < handle
    %DATAPIPE Special form of Datastub that allows for appending.
    % Current limitations: DataPipe currently only supports the types
    % represented by dataType.  No strings, or references are allowed with
    % DataPipes.
    properties
        % offset of dataset to append.  May be used to overwrite data.
        offset;
        
        % The ideal size of chunks for incremental data appending.
        % if the chunkSize is empty, an optimal size will be guessed when the
        % dataset is created.
        chunkSize;
        
        % DEFLATE level for the dataset. -1 for disabled compression
        compressionLevel;
        
        % one of float|double|uint8|int8|int16|uint16|int32|uint32|int64|uint64
        dataType;
        
        data; % Writable data
    end
    
    properties (SetAccess = private, Dependent)
        isBound; % this datapipe is dependent on an existing dataset.
    end
    
    properties (SetAccess = private)
        filename = '';
        path = '';
        maxSize; % maximum dimension size
        axis; % indices indicating which dimension to append data to.
    end
    
    properties (Access = private, Constant)
        SUPPORTED_DATATYPES = {...
            'float', 'double', 'uint8', 'int8', 'uint16', 'int16',...
            'uint32', 'int32', 'uint64', 'int64'
            };
    end
    
    methods % lifecycle
        function obj = DataPipe(varargin)
            p = inputParser;
            p.addParameter('maxSize', [Inf, 1]);
            p.addParameter('axis', 1);
            p.addParameter('offset', 0);
            p.addParameter('chunkSize', []);
            p.addParameter('compressionLevel', 3);
            p.addParameter('dataType', '');
            p.addParameter('data', []);
            p.addParameter('filename', '');
            p.addParameter('path', '');
            p.KeepUnmatched = true;
            p.parse(varargin{:});
                        
            hasFilename = ~isempty(p.Results.filename);
            hasPath = ~isempty(p.Results.path);
            assert(~xor(hasFilename, hasPath), ['A non-empty filename and '...
                'path are required to create a bound DataPipe.  Only '...
                'one of the above were specified.']);
            if hasFilename && hasPath
                obj.loadFromFile(...
                    p.Results.filename,...
                    p.Results.path,...
                    p.Results.axis);
                dependentProperties = {...
                    'offset',...
                    'chunkSize',...
                    'compressionLevel',...
                    'dataType',...
                    'data',...
                    };
                extraProperties = setdiff(dependentProperties, p.Unmatched);
                if ~isempty(extraProperties)
                    formattedProperties = cell(size(dependentProperties));
                    for i = 1:length(dependentProperties)
                        formattedProperties{i} =...
                            ['    ', dependentProperties{i}];
                    end
                    warning(['Other keyword arguments were added along with '...
                        'a valid filename and path.  Since the filename and '...
                        'path are valid, the following extra properties will '...
                        'be superceded by the configuration on file:\n%s'],...
                        strjoin(formattedProperties, newline));
                end
                % the datapipe is now bound and cannot be further altered.
                return;
            end
            
            if isempty(p.Results.maxSize)
                assert(~isempty(p.Results.data), ['If maxSize is not '...
                    'specified then a non-empty data array must be specified.']);
                obj.maxSize = size(p.Results.data);
                obj.maxSize(p.Results.axis) = Inf;
            else
                obj.maxSize = p.Results.maxSize;
            end
            obj.axis = p.Results.axis;
            obj.offset = p.Results.offset;
            obj.data = p.Results.data;
            
            if ~isempty(p.Results.dataType)
                obj.dataType = p.Results.dataType;
            end
            obj.chunkSize = p.Results.chunkSize;
        end
    end
    
    methods % get/set
        function tf = get.isBound(obj)
            tf = ~isempty(obj.filename) && ~isempty(obj.path);
        end
        
        function set.axis(obj, val)
            assert(isnumeric(val)...
                && isscalar(val)...
                && val > 0 ...
                && val <= length(obj.maxSize),...
                'NWB:Untyped:DataPipe:SetAxis:InvalidArgument',...
                'Axis must be scalar index within (0, %d]', length(obj.maxSize));
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
            assert(isnumeric(val),...
                'NWB:Untyped:DataPipe:SetChunkSize:InvalidType',...
                '`chunkSize` must be numeric.');
            val = ceil(val);
            assert(~obj.isBound,...
                'NWB:Untyped:DataPipe:SetChunkSize:SettingLocked',...
                ['`chunkSize` cannot be reset if this datapipe is bound to '...
                'an existing NWB file.']);
            
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
            assert(isempty(val) || length(obj.maxSize) == length(size(val)),...
                'NWB:Untyped:DataPipe:SetData:InvalidRank',...
                'Data rank must be %d', length(obj.maxSize));
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
    
    methods (Access = private)
        function loadFromFile(obj, filename, path, axis)
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
            
            obj.maxSize = max_size;
            obj.axis = axis;
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
        
        function fid = getFile(obj, access)
            if nargin < 2
                access = 'H5F_ACC_RDONLY';
            end
            fid = H5F.open(obj.filename, access, 'H5P_DEFAULT');
        end
        
        function did = getDataset(obj, access)
            if nargin < 2
                access = 'H5F_ACC_RDONLY';
            end
            fid = obj.getFile(access);
            did = H5D.open(fid, obj.path, 'H5P_DEFAULT');
            H5F.close(fid);
        end
        
        function sid = makeSelection(obj, dataSize)
            did = obj.getDataset();
            sid = H5D.get_space(did);
            H5S.select_none(sid);
            start_indices = zeros(1, length(obj.maxSize));
            start_indices(obj.axis) = obj.offset;
            
            h5_start = fliplr(start_indices);
            h5_stride = [];
            h5_count = fliplr(dataSize);
            h5_block = [];
            H5S.select_hyperslab(sid,...
                'H5S_SELECT_OR',...
                h5_start,...
                h5_stride,...
                h5_count,...
                h5_block);
            H5D.close(did);
        end
        
        function expandDataset(obj, data_size)
            did = obj.getDataset('H5F_ACC_RDWR');
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
                'Non-axis data size should match maxSize.');
            H5D.set_extent(did, fliplr(new_extents));
        end
        
        function dcpl = makeDcpl(obj)
            % dcpl -> Dataset Creation Property List
            dcpl = H5P.create('H5P_DATASET_CREATE');
            if isempty(obj.chunkSize)
                obj.chunkSize =...
                    types.untyped.datapipe.guessChunkSize(...
                    obj.dataType,...
                    obj.maxSize);
            end
            H5P.set_chunk(dcpl, fliplr(obj.chunkSize));
            
            if obj.compressionLevel ~= -1
                H5P.set_deflate(dcpl, obj.compressionLevel);
            end
        end
    end
    
    methods
        function size = get_size(obj)
            assert(obj.isBound,...
                'NWB:Untyped:DataPipe:GetSize:NoAvailableSize',...
                ['DataPipe must first be bound to a valid hdf5 filename and '...
                'path to query its current dimensions.']);
            fid = obj.getFile();
            did = obj.getDataset();
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
            
            obj.expandDataset(data_size);
            sid = obj.makeSelection(data_size);
            
            fid = obj.getFile('H5F_ACC_RDWR');
            [mem_tid, mem_sid, data] = io.mapData2H5(fid, data, 'forceArray');
            h5_count = fliplr(data_size);
            H5S.set_extent_simple(mem_sid, rank, h5_count, h5_count);
            
            did = obj.getDataset('H5F_ACC_RDWR');
            H5D.write(did, mem_tid, mem_sid, sid, 'H5P_DEFAULT', data);
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
            
            dcpl = obj.makeDcpl();
            dapl = 'H5P_DEFAULT';
            lcpl = 'H5P_DEFAULT';
            tid = io.getBaseType(obj.dataType);
            did = H5D.create(fid, fullpath, tid, sid, lcpl, dcpl, dapl);
            
            H5P.close(dcpl);
            H5S.close(sid);
            if ~ischar(tid)
                H5T.close(tid);
            end
            H5D.close(did);
            
            % since you can't reassign obj.data while filename and path are bound
            % we set a temporary variable here instead and relinquish the data
            % from the object.  That way, the memory is cleaned up.
            queued = obj.data;
            emptySize = obj.maxSize;
            emptySize(1) = 0;
            obj.data = zeros(emptySize, obj.dataType);            
            % bind to this file.
            obj.filename = H5F.get_name(fid);
            obj.path = fullpath;
            obj.append(queued);
        end
    end
end

