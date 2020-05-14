classdef DataPipe < handle
    %DATAPIPE Summary of this class goes here
    %   Detailed explanation goes here
    
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
            import types.untyped.datapipe.properties.Chunking;
            import types.untyped.datapipe.properties.Compression;
            import types.untyped.datapipe.properties.Shuffle;
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
            assert(~xor(hasFilename, hasPath), ['A non-empty filename and path are '...
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
                    warning(['Other keyword arguments were added along with a valid '...
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
            
            if p.Results.hasShuffle
                obj.internal.setPipeProperties(Shuffle());
            end
            
            if ~isempty(p.Results.compressionLevel)
                obj.internal.setPipeProperties(Compression(...
                    p.Results.compressionLevel));
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
        function append(obj, data)
            obj.internal.append(data);
        end
        
        function refs = export(obj, fid, fullpath, refs)
            obj.internal = obj.internal.write(fid, fullpath);
        end
    end
end