classdef BlueprintPipe < types.untyped.datapipe.Pipe
    %BLUEPRINTPIPE or "unbound", this DataPipe type is only intended for in-memory
    % operations.  When exported, it will become an Input Pipe.
    
    properties
        data = []; % queued data
        config = types.untyped.datapipe.Configuration.empty;
    end
    
    properties (SetAccess = private)
        pipeProperties = {};
    end
    
    methods % lifecycle
        function obj = BlueprintPipe(config)
            errorId = 'NWB:Untyped:DataPipe:InvalidConstructorArgument';
            
            assert(isa(config, 'types.untyped.datapipe.Configuration'),...
                errorId,...
                ['Config must be a valid datapipe Configuration type.\n'...
                'Expecting `types.untyped.datapipe.Configuration.\n'...
                'Got       `%s`'], class(config));
            obj.config = config;
        end
    end
    
    methods % set/get
        function set.config(obj, val)
            assert(isa(val, 'types.untyped.datapipe.Configuration'),...
                'NWB:Untyped:DataPipe:Blueprint:InvalidConfiguration',...
                ['config property must be a '...
                'types.untyped.datapipe.Configuration object.']);
            obj.config = val;
        end
        
        function set.data(obj, val)
            import types.untyped.datapipe.Configuration;
            assert(any(strcmp(class(val), Configuration.SUPPORTED_DATATYPES)),...
                'NWB:Untyped:DataPipe:Blueprint:InvalidData',...
                'Only the following numeric types are supported %s',...
                strjoin(Configuration.SUPPORTED_DATATYPES, '|'));
            obj.data = val;
        end
    end
    
    methods
        function addPipeProperties(obj, varargin)
            for i = 1:length(varargin)
                obj.addPipeProperty(varargin{i});
            end
        end
        
        function tf = hasPipeProperty(obj, name)
            for i = 1:length(obj.pipeProperties)
                if isa(obj.pipeProperties{i}, name)
                    tf = true;
                    return;
                end
            end
            tf = false;
        end
    end
    
    methods (Access = private)
        function addPipeProperty(obj, prop)
            assert(isa(prop, 'types.untyped.datapipe.Property'),...
                'Can only add filters.');
            
            for i = 1:length(obj.pipeProperties)
                if isa(prop, class(obj.pipeProperties{i}))
                    obj.pipeProperties{i} = prop;
                    return;
                end
            end
            obj.pipeProperties{end+1} = prop;
        end
        
        function dcpl = makeDcpl(obj)
            dcpl = H5P.create('H5P_DATASET_CREATE');
            for i = 1:length(obj.pipeProperties)
                obj.pipeProperties{i}.addTo(dcpl);
            end
        end
    end
    
    %% Pipe
    methods
        function append(~, ~)
            error('NWB:Untyped:DataPipe:Blueprint:CannotAppend',...
                'BlueprintPipes must be exported before ');
        end
        
        function config = getConfig(obj)
            config = obj.config;
        end
        
        function pipe = write(obj, fid, fullpath) % standard export function
            import types.untyped.datapipe.Configuration;      
            import types.untyped.datapipe.properties.Chunking;
            import types.untyped.datapipe.guessChunkSize;
            errorId = 'NWB:Untyped:DataPipe:Blueprint:CannotExport';
            
            if isempty(obj.config)
                config = Configuration.fromData(obj.data); %#ok<PROPLC>
            else
                config = obj.config; %#ok<PROPLC>
            end
            
            maxSize = config.maxSize; %#ok<PROPLC>
            
            if ~isempty(obj.data)
                formatDataSize = strjoin(...
                    cellfun(@num2str, num2cell(size(obj.data)),...
                    'UniformOutput', false),...
                    ', ');
                formatMaxSize = strjoin(...
                    cellfun(@num2str, num2cell(maxSize),...
                    'UniformOutput', false),...
                    ', ');
                assert(length(size(obj.data)) == length(maxSize)...
                    && all(size(obj.data) <= maxSize),...
                    errorId, ['Data size must be bound by maxSize.\n'...
                    'Data size was [%s].  maxSize configured to be [%s]'],...
                    formatDataSize, formatMaxSize);
            end
            
            dataType = config.dataType; %#ok<PROPLC>
            tid = io.getBaseType(dataType);
            
            sid = allocateSpace(maxSize);
            
            lcpl = 'H5P_DEFAULT';
            
            if ~obj.hasPipeProperty(...
                    'types.untyped.datapipe.properties.Chunking')
                obj.addPipeProperty(...
                    Chunking(guessChunkSize(dataType, maxSize)));
            end
            dcpl = obj.makeDcpl();
            dapl = 'H5P_DEFAULT';
            did = H5D.create(fid, fullpath, tid, sid, lcpl, dcpl, dapl);
            
            H5D.close(did);
            H5P.close(dcpl);
            H5S.close(sid);
            if ~ischar(tid)
                H5T.close(tid);
            end

            pipe = types.untyped.datapipe.BoundPipe(...
                H5F.get_name(fid), fullpath, obj.config);
            if ~isempty(obj.data)
                pipe.append(cast(obj.data, obj.config.dataType));
            end
        end
    end
end

function sid = allocateSpace(maxSize)
rank = length(maxSize);
h5_dims = zeros(1, rank);
h5_rank = find(maxSize == 1);
if isempty(h5_rank)
    h5_rank = rank;
end
h5_maxdims = fliplr(maxSize(1:h5_rank));
h5_unlimited = H5ML.get_constant_value('H5S_UNLIMITED');
h5_maxdims(isinf(h5_maxdims)) = h5_unlimited;
sid = H5S.create_simple(rank, h5_dims, h5_maxdims);
end
