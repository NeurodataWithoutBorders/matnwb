classdef Blueprint < types.untyped.datapipe.Pipe
    %BLUEPRINT or "unbound", this DataPipe type is only intended for in-memory
    % operations.  When exported, it will become an Input Pipe.
    
    properties
        data = []; % queued data
        config = types.untyped.datapipe.Configuration.empty;
    end
    
    properties (SetAccess = private)
        filters = types.untyped.datapipe.Filter.empty;
    end
    
    methods % lifecycle
        function obj = Blueprint(config)
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
        function addFilters(obj, varargin)
            for i = 1:length(varargin)
                obj.addFilter(varargin{i});
            end
        end
        
        function tf = hasFilter(name)
            for i = 1:length(obj.filters)
                if strcmp(name, obj.filters(i).getName())
                    tf = true;
                    return;
                end
            end
            tf = false;
        end
    end
    
    methods (Access = private)
        function addFilter(obj, filter)
            assert(isa(filter, 'types.untyped.datapipe.Filter'),...
                'Can only add filters.');
            hasPrecond = isa(filter,...
                'types.untyped.datapipe.filter.interfaces.hasPrecondition');
            if hasPrecond
                filter.checkPrecondition(obj);
            end
            
            for i = 1:length(obj.filters)
                if strcmp(obj.filters(i).getName(), filter.getName())
                    obj.filters(i) = filter;
                    return;
                end
            end
            obj.filters(end+1) = filter;
        end
        
        function dcpl = makeDcpl(obj)
            dcpl = H5P.create('H5P_DATASET_CREATE');
            for i = 1:length(values(obj.filters))
                obj.filters(i).addTo(dcpl);
            end
        end
    end
    
    methods % exportable
        function export(obj, fid, fullpath, ~) % standard export function
            import types.untyped.datapipe.Configuration;
            errorId = 'NWB:Untyped:DataPipe:Blueprint:CannotExport';
            
            if isempty(obj.config)
                config = Configuration.fromData(obj.data); %#ok<PROPLC>
            else
                config = obj.config; %#ok<PROPLC>
            end
            
            maxSize = config.maxSize; %#ok<PROPLC>
            
            if ~isempty(obj.data)
                formatDataSize = strjoin(...
                    cellfun(@num2str, num2cell(size(obj.data))), ', ');
                formatMaxSize = strjoin(...
                    cellfun(@num2str, num2cell(maxSize)), ', ');
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
            dcpl = obj.makeDcpl();
            dapl = 'H5P_DEFAULT';
            did = H5D.create(fid, fullpath, tid, sid, lcpl, dcpl, dapl);
            
            H5D.close(did);
            H5P.close(dcpl);
            H5S.close(sid);
            if ~ischar(tid)
                H5T.close(tid);
            end
            
            % since you can't reassign obj.data while filename and path are bound
            % we set a temporary variable here instead and relinquish the data
            % from the object.  That way, the memory is cleaned up.
            queued = obj.data;
            emptySize = maxSize;
            emptySize(1) = 0;
            obj.data = zeros(emptySize, dataType);
            % bind to this file.
            obj.filename = H5F.get_name(fid);
            obj.path = fullpath;
            obj.append(queued);
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