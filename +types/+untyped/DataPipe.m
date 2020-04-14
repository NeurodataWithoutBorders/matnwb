classdef DataPipe < handle
    %DATAPIPE Special form of Datastub that allows for appending.
    % Current limitations: DataPipe currently only supports the types
    % represented by dataType.  No strings, or references are allowed with
    % DataPipes.
    properties (SetAccess = private)
        internalPipe;
    end
    
    properties (SetAccess = private, Dependent)
        config;
    end
    
    methods % lifecycle
        function obj = DataPipe(varargin)
            import types.untyped.datapipe.BoundPipe;
            import types.untyped.datapipe.Configuration;
            import types.untyped.datapipe.BlueprintPipe;
            import types.untyped.datapipe.properties.Chunking;
            
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
                obj.internalPipe = BoundPipe(filename, path);
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
                return;
            end

            if isempty(p.Results.maxSize)
                assert(~isempty(p.Results.data), ['If maxSize is not '...
                    'specified then a non-empty data array must be specified.']);
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
                config.dataType = class(p.Results.data);
            end
            
            obj.internalPipe = BlueprintPipe(config);
            if ~isempty(p.Results.chunkSize)
                obj.internalPipe.addPipeProperties(...
                    Chunking(p.Results.chunkSize));
            end
            obj.internalPipe.data = p.Results.data;
        end
    end
    
    methods % set/get
        function config = get.config(obj)
            config = obj.internalPipe.getConfig();
        end
    end
    
    methods
        function append(obj, data)
            obj.internalPipe.append(data);
        end
        
        function refs = export(obj, fid, fullpath, refs)
            obj.internalPipe = obj.internalPipe.write(fid, fullpath);
        end
    end
end

