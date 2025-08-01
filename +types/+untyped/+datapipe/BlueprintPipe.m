classdef BlueprintPipe < types.untyped.datapipe.Pipe
    %BLUEPRINTPIPE or "unbound", this DataPipe type is only intended for in-memory
    % operations.  When exported, it will become an Input Pipe.
    
    properties
        data = []; % queued data
    end
    
    properties (SetAccess = private)
        pipeProperties = {};
        config = types.untyped.datapipe.Configuration.empty;
    end
    
    properties (Dependent)
        axis;
        offset;
        dataType;
        maxSize;
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
        function set.data(obj, val)
            import types.untyped.datapipe.Configuration;
            assert(any(strcmp(class(val), Configuration.SUPPORTED_DATATYPES)),...
                'NWB:Untyped:DataPipe:Blueprint:InvalidData',...
                'Only the following numeric types are supported %s',...
                strjoin(Configuration.SUPPORTED_DATATYPES, '|'));
            obj.data = val;
        end
        
        function val = get.axis(obj)
            val = obj.config.axis;
        end
        
        function set.axis(obj, val)
            obj.config.axis = val;
        end
        
        function val = get.offset(obj)
            val = obj.config.offset;
        end
        
        function set.offset(obj, val)
            obj.config.offset = val;
        end
        
        function val = get.dataType(obj)
            val = obj.config.dataType;
        end
        
        function set.dataType(obj, val)
            obj.config.dataType = val;
        end
        
        function val = get.maxSize(obj)
            val = obj.config.maxSize;
        end
    end
    
    methods
        function setPipeProperties(obj, varargin)
            for i = 1:length(varargin)
                obj.setPipeProperty(varargin{i});
            end
        end

        function data = load(obj, varargin)
            data = obj.data(varargin{:});
        end
    end
    
    methods (Access = private)
        function dcpl = makeDcpl(obj)
            dcpl = H5P.create('H5P_DATASET_CREATE');
            for i = 1:length(obj.pipeProperties)
                obj.pipeProperties{i}.addTo(dcpl);
            end
        end
    end
    
    %% Pipe
    methods
        function append(obj, data)
            validateattributes(data, {obj.dataType}, {});
            if ~isscalar(obj.data) && isvector(obj.data)
                % don't trust obj.axis if obj.data is a vector. Both are
                % coerced to vertical arrays when bound to file.
                % thus, to ensure consistency, we pretend that the
                % concatenation is correct.
                if isrow(obj.data)
                    concatenationDimension = 2;
                else
                    concatenationDimension = 1;
                end
            else
                concatenationDimension = obj.axis;
            end
            obj.data = cat(concatenationDimension, obj.data, data);
        end
        
        function setPipeProperty(obj, prop)
            assert(isa(prop, 'types.untyped.datapipe.Property'),...
                'Can only add filters.');

            isDynamicFilter = isa(prop, ...
                'types.untyped.datapipe.properties.DynamicFilter');
            
            % dedup pipe properties if it already exists with special case
            % behavior for dynamic filters.
            for i = 1:length(obj.pipeProperties)
                pipeProp = obj.pipeProperties{i};

                isSameClass = isa(prop, class(pipeProp));

                if isSameClass
                    if isDynamicFilter && prop.dynamicFilter ~= pipeProp.dynamicFilter
                        continue;
                    end

                    obj.pipeProperties{i} = prop;
                    return;
                end
            end
            obj.pipeProperties{end+1} = prop;
         end
        
        function property = getPipeProperty(obj, type)
            property = [];
            for i = 1:length(obj.pipeProperties)
                if isa(obj.pipeProperties{i}, type)
                    property = obj.pipeProperties{i};
                    return;
                end
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
        
        function removePipeProperty(obj, type)
            found = false(size(obj.pipeProperties));
            for i = 1:length(obj.pipeProperties)
                found = isa(obj.pipeProperties{i}, type);
            end
            obj.pipeProperties(found) = [];
        end
        
        function pipe = write(obj, fid, fullpath)
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
                errorMessage = sprintf(['Data size must be bound by maxSize.\n'...
                    'Data size was [%s].  maxSize configured to be [%s]'],...
                    formatDataSize, formatMaxSize);

                dataSize = size(obj.data);
                if 1 == length(maxSize)
                    assert(1 >= sum(dataSize > 1) && max(dataSize) <= maxSize, ...
                        errorId, errorMessage);
                else
                    assert(length(dataSize) == length(maxSize) && all(dataSize <= maxSize), ...
                        errorId, errorMessage);
                end
            end
            
            dataType = config.dataType; %#ok<PROPLC>
            tid = io.getBaseType(dataType);
            
            sid = allocateSpace(maxSize);
            
            lcpl = 'H5P_DEFAULT';
            
            if ~obj.hasPipeProperty(...
                    'types.untyped.datapipe.properties.Chunking')
                obj.setPipeProperty(...
                    Chunking(guessChunkSize(dataType, maxSize)));
            end
            dcpl = obj.makeDcpl();
            dapl = 'H5P_DEFAULT';
            
            try
                did = H5D.create(fid, fullpath, tid, sid, lcpl, dcpl, dapl);
            catch ME
                % Clean up H5 id before throwing error
                H5P.close(dcpl);
                H5S.close(sid);
                if ~ischar(tid)
                    H5T.close(tid);
                end

                if contains(ME.message, "name already exists")
                    % Improve error message if this fails because dataset
                    % already exists.
                    error('NWB:BlueprintPipe:DatasetAlreadyExists', ...
                        ['Cannot export an unbound DataPipe to an existing file that already ' ...
                         'contains the dataset at path "%s". ' ...
                         'To fix this: either export to a new file, or use export mode "overwrite" ' ...
                         'to replace the existing file, or read the existing file and modify it in place.'], ...
                         fullpath);
                else
                    rethrow(ME);
                end
            end
            
            H5D.close(did);
            H5P.close(dcpl);
            H5S.close(sid);
            if ~ischar(tid)
                H5T.close(tid);
            end
            
            cached = obj.data;
            pipe = types.untyped.datapipe.BoundPipe(...
                H5F.get_name(fid), fullpath, obj.config);
            if ~isempty(cached)
                pipe.append(cast(cached, obj.config.dataType));
            end
        end
    end
end

function sid = allocateSpace(maxSize)
rank = length(maxSize);
h5_dims = zeros(1, rank);
h5_maxdims = fliplr(maxSize);
h5_unlimited = H5ML.get_constant_value('H5S_UNLIMITED');
h5_maxdims(isinf(h5_maxdims)) = h5_unlimited;
sid = H5S.create_simple(rank, h5_dims, h5_maxdims);
end
