classdef DataPipe < handle
    %DATAPIPE gives advanced write directions to HDF5 for a dataset for
    %chunking, compression, and iterative write.
    %   DATAPIPE directs HDF5 to use chunking and GZIP compression when 
    %   saving the dataset. The chunk size is automatically determined and
    %   the compression level is 3 by default.
    %
    %	DATAPIPE(..., 'data', DATA) Write DATA in the Dataset.
    %
    %   DATAPIPE(..., 'maxSize', MAXSIZE) Sets the maximum size of the HDF5
    %   Dataset. Unless using iterative writing, this should match the size
    %   of Data. To append data later, use the maxSize for the full 
    %   dataset. You can use Inf for a value of a dimension if you do not
    %   know its final size.
    %
    %   DATAPIPE(..., 'axis', AXIS) Set which axis to increment when
    %   appending more data.
    %
    %   DATAPIPE(..., 'dataType', DATATYPE) Sets the type of the data. This
    %   must be a numeric data type. Useful to include when using iterative
    %   write to append data as the appended data must be the same data
    %   type. If data is provided and dataType is not, the dataType is
    %   inferred from the provided data.
    %
    %   DATAPIPE(..., 'chunkSize', CHUNKSIZE) Sets chunk size. Must be less
    %   than maxSize. If not provided, the CHUNKSIZE will be automatically
    %   determined.
    %
    %   DATAPIPE(..., 'compressionLevel', COMPRESSIONLEVEL) sets a
    %   GZIP compression level over than the default of 3
    %
    %   DATAPIPE(..., 'offset', OFFSET) Axis offset of dataset to append.
    %   May be used to overwrite data.
    
    properties (SetAccess = private)
        internal;
    end
    
    properties (Dependent)
        axis;
        offset;
        dataType;
        chunkSize;
        compressionLevel;
        hasShuffle;
    end
    
    methods % lifecycle
        function obj = DataPipe(varargin)
            import types.untyped.datapipe.BoundPipe;
            import types.untyped.datapipe.BlueprintPipe;
            import types.untyped.datapipe.Configuration;
            import types.untyped.datapipe.properties.*;
            import types.untyped.datapipe.guessChunkSize;
            
            p = inputParser;
            p.addParameter('maxSize', [Inf, 1]);
            p.addParameter('axis', 1, @(x) isnumeric(x) && isscalar(x) && x > 0);
            p.addParameter('offset', 0, @(x) isnumeric(x) && isscalar(x) && x >= 0);
            p.addParameter('chunkSize', []);
            p.addParameter('compressionLevel', 3, @(x) isnumeric(x)...
                && isscalar(x)...
                && x >= -1);
            p.addParameter('dataType', '');
            p.addParameter('data', []);
            p.addParameter('filename', '');
            p.addParameter('path', '');
            p.addParameter('hasShuffle', false);
            p.KeepUnmatched = true;
            p.parse(varargin{:});
            
            hasFilename = ~isempty(p.Results.filename);
            hasPath = ~isempty(p.Results.path);
            assert(~xor(hasFilename, hasPath),...
                'NWB:DataPipe:MismatchedArguments',...
                ['A non-empty filename and path are '...
                'required to create a bound DataPipe.  Only one of the above were '...
                'specified.']);
            if hasFilename && hasPath
                obj.internal = BoundPipe(p.Results.filename, p.Results.path);
                dependentProperties = {...
                    'offset',...
                    'chunkSize',...
                    'compressionLevel',...
                    'dataType',...
                    'data',...
                    };
                
                extraProperties = intersect(...
                    dependentProperties,...
                    fieldnames(p.Unmatched)...
                    );
                if ~isempty(extraProperties)
                    formattedProperties = cell(size(dependentProperties));
                    for i = 1:length(dependentProperties)
                        formattedProperties{i} =...
                            ['    ', dependentProperties{i}];
                    end
                    warning('NWB:DataPipe:UnusedArguments',...
                        ['Other keyword arguments were added along with a valid '...
                        'filename and path.  Since the filename and path are valid, the '...
                        'following extra properties will be superceded by the '...
                        'configuration on file:\n%s'],...
                        strjoin(formattedProperties, newline));
                end
                return;
            end
            
            if ~isempty(p.Results.data)
                maxSize = size(p.Results.data);
                maxSize(p.Results.axis) = Inf;
            else
                maxSize = p.Results.maxSize;
            end
            config = Configuration(maxSize);
            config.axis = p.Results.axis;
            config.offset = p.Results.offset;
            
            if isempty(p.Results.data)
                config.dataType = p.Results.dataType;
            else
                if ~isempty(p.Results.dataType)
                    warning('NWB:DataPipe:RedundantDataType',...
                        ['`datatype` parameter will be ignored in lieu of '...
                        'provided `data` value type.']);
                end
                config.dataType = class(p.Results.data);
            end
            
            obj.internal = BlueprintPipe(config);
            if isempty(p.Results.chunkSize)
                chunkSize = guessChunkSize(config.dataType, config.maxSize);
            else
                chunkSize = p.Results.chunkSize;
            end
            obj.internal.setPipeProperties(Chunking(chunkSize));
            
            if ~isempty(p.Results.compressionLevel)
                obj.internal.setPipeProperties(Compression(...
                    p.Results.compressionLevel));
            end
            
            if p.Results.hasShuffle
                obj.internal.setPipeProperties(Shuffle());
            end
            
            obj.internal.data = p.Results.data;
        end
    end
    
    methods % set/get
        function val = get.axis(obj)
            val = obj.internal.axis;
        end
        
        function set.axis(obj, val)
            obj.internal.axis = val;
        end
        
        function val = get.offset(obj)
            val = obj.internal.offset;
        end
        
        function set.offset(obj, val)
            obj.internal.offset = val;
        end
        
        function val = get.dataType(obj)
            val = obj.internal.dataType;
        end
        
        function set.dataType(obj, val)
            obj.internal.dataType = val;
        end
        
        function val = get.chunkSize(obj)
            val = obj.internal.getPipeProperty(...
                'types.untyped.datapipe.properties.Chunking').chunkSize;
        end
        
        function set.chunkSize(obj, val)
            import types.untyped.datapipe.properties.Chunking;
            obj.internal.setPipeProperty(Chunking(val));
        end
        
        function val = get.compressionLevel(obj)
            val = obj.internal.getPipeProperty(...
                'types.untyped.datapipe.properties.Compression').level;
        end
        
        function set.compressionLevel(obj, val)
            import types.untyped.datapipe.properties.Compression;
            obj.internal.setPipeProperty(Compression(val));
        end
        
        function tf = get.hasShuffle(obj)
            tf = obj.internal.hasPipeProperty(...
                'types.untyped.datapipe.properties.Shuffle');
        end
        
        function set.hasShuffle(obj, tf)
            import types.untyped.datapipe.properties.Shuffle;
            if tf
                obj.internal.setPipeProperty(Shuffle());
            else
                obj.internal.removePipeProperty(...
                    'types.untyped.datapipe.properties.Shuffle');
            end
        end
    end
    
    methods
        function data = load(obj, varargin)
            assert(isa(obj.internal, 'types.untyped.datapipe.BoundPipe'),...
                'NWB:DataPipe:LoadingUnboundPipe',...
                ['DataPipe must be successfully exported before DataStub '...
                'features are allowed.']);
            data = obj.internal.load(varargin{:});
        end
        
        function append(obj, data)
            obj.internal.append(data);
        end
        
        function refs = export(obj, fid, fullpath, refs)
            obj.internal = obj.internal.write(fid, fullpath);
        end
    end
end
