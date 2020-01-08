classdef DataPipe < nwb.interface.Exportable
    %DATAPIPE Special form of Datastub that allows for appending.
    % Current limitations: DataPipe currently only supports the types represented
    % by dataType.  No strings, or references are allowed with DataPipes.
    
    properties
        axis; % axis index in MATLAB format indicating which axis to increment.
        offset; % axis offset of dataset to append.  May be used to overwrite data.
        chunkSize; % ideal size of chunks for incremental data appending.
        compressionLevel; % DEFLATE level for the dataset. -1 for disabled compression
        dataType; % one of float|double|uint8|int8|int16|uint16|int32|uint32|int64|uint64
        data; % Writable data 
    end
    
    properties (SetAccess = private)
        isBound; % is associated with a filename and path
        filename;
        path;
        maxSize; % maximum dimension size
    end
    
    properties (Access = private, Constant)
        SUPPORTED_DATATYPES = {...
            'float', 'double', 'uint8', 'int8', 'uint16', 'int16', 'uint32',...
            'int32', 'uint64', 'int64'
            };
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
            p.addParameter('compressionLevel', -1);
            p.parse(varargin{:});
            
            obj.filename = p.Results.filename;
            obj.path = p.Results.path;
            obj.axis = p.Results.axis;
            obj.offset = p.Results.offset;
            obj.chunkSize = p.Results.chunkSize;
            obj.dataType = p.Results.dataType;
            obj.compressionLevel = p.Results.compressionLevel;
        end
    end
    
    methods % get/set
        function tf = get.isBound(obj)
            try
                File = h5.File.open(obj.filename);
                h5.Dataset.open(File, obj.path);
                
                tf = true;
            catch
                tf = false;
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
            import types.untyped.DataPipe;
            
            MSG_ID_CONTEXT = 'NWB:Untyped:DataPipe:SetDataType:';
            
            assert(ischar(val),...
                [MSG_ID_CONTEXT 'InvalidType'],...
                '`dataType` must be a string');
            
            assert(any(strcmp(val, DataPipe.SUPPORTED_DATATYPES)),...
                [MSG_ID_CONTEXT 'InvalidType'],...
                '`dataType` must be one of the supported datatypes `%s`',...
                strjoin(DataPipe.SUPPORTED_DATATYPES, '|'));
            
            assert(~obj.isBound,...
                [MSG_ID_CONTEXT 'SettingLocked'],...
                ['`dataType` cannot be reset if this datapipe is bound to an '...
                'existing NWB file.']);
            
            obj.dataType = val;
        end
        
        function set.data(obj, val)
            assert(~obj.isBound,...
                'NWB:Untyped:DataPipe:SetData:SettingLocked',...
                ['`data` cannot be set if this DataPipe is bound to an existing NWB '...
                'file']);
            obj.dataType = class(val);
            obj.data = val;
        end
        
        function set.compressionLevel(obj, val)
            MSG_ID_CONTEXT = 'NWB:Untyped:DataPipe:SetCompressionLevel:';
            
            assert(~obj.isBound,...
                [MSG_ID_CONTEXT 'SettingLocked'],...
                ['`compressionLevel` can only be set if DataPipe has not yet been '...
                'bound to a NWBFile.']);
            assert(isscalar(val) && isnumeric(val),...
                [MSG_ID_CONTEXT 'InvalidType'],...
                '`compressionLevel` must be a scalar numeric value.');
            
            val = ceil(val);
            if val < -1 || val > 9
                warning([MSG_ID_CONTEXT 'OutOfRange'],...
                    ['`compressionLevel` range is [0, 9] or -1 for off.  '...
                    'Found %d, Disabling.'], val);
                val = -1;
            end
            
            obj.compressionLevel = val;
        end
    end
    
    methods
        function size = get_size(obj)
            assert(obj.isBound,...
                'NWB:Untyped:DataPipe:GetSize:NoAvailableSize',...
                ['DataPipe must first be bound to a valid hdf5 filename and path to '...
                'query its current dimensions.']);
            
            File = h5.File.open(obj.filename);
            Dataset = h5.Dataset.open(File, obj.path);
            size = Dataset.dims;
        end
        
        function append(obj, data)
            if isempty(data)
                return;
            end
            
            MSG_ID_CONTEXT = 'NWB:Untyped:DataPipe:Append:';
            assert(isa(data, obj.dataType),...
                [MSG_ID_CONTEXT 'InvalidType'],...
                'Data must match dataType')
            assert(obj.isBound,...
                [MSG_ID_CONTEXT 'ExportRequired'],...
                ['Appending to a dataset requires exporting and re-importing '...
                    'a valid NWB file.']);
                
            File = h5.File.open(obj.filename, 'access', h5.const.FileAccess.ReadWrite);
            Dataset = h5.Dataset.open(File, obj.path);
            
            rank = length(obj.maxSize);
            shape_coords = ones(1, rank);
            shape_coords(1:length(size(data))) = size(data);
            offset_coords = ones(1, rank);
            offset_coords(obj.axis) = obj.offset;
            
            SelectSlab = h5.space.Hyperslab('shape', shape_coords, 'offset', offset_coords);
            Dataset.write(data, 'selection', SelectSlab);

            obj.offset = obj.offset + size(data, obj.axis);
        end
        
        function MissingViews = export(obj, Parent, name)
            MissingViews = nwb.interface.Reference.empty;
            if obj.isBound
                return;
            end
            
            MemType = h5.Type.from_matlab(obj.dataType);
            MemSpace = h5.Space.from_matlab(size(obj.data));
            MemSpace.extents = obj.maxSize;
            
            Dcpl = h5.DatasetCreationPropertyList.create();
            Dcpl.chunkSize = obj.chunkSize;
            if obj.compressionLevel ~= -1
                Dcpl.deflateLevel = obj.compressionLevel;
            end
            
            Dataset = h5.Dataset.create(Parent, name,...
                'type', MemType,...
                'space', MemSpace,...
                'dcpl', Dcpl);
            
            data = obj.data;
            obj.data = cast([], obj.dataType);
            
            % bind to this file.
            obj.filename = Parent.get_file().filename;
            obj.path = Dataset.get_name();
            
            obj.append(data);
        end
    end
end

