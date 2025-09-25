classdef (Sealed) DataPipe < handle
% DATAPIPE - Configures and performs advanced HDF5 read/write for a dataset 
%            (chunking, compression, incremental writes)
%
% Description:
%  DATAPIPE directs HDF5 to use chunking and GZIP compression when
%  saving the dataset. The chunk size is automatically determined and
%  the compression level is 3 by default.
%
% Syntax:
%  dataPipe = types.untyped.DATAPIPE(Name, Value) creates a DataPipe object
%  using one or more name-value pairs to control the configuration of the
%  DataPipe. NB: One of data or maxSize is required.
% 
% Input Arguments:
%  - options (name-value pairs) -
%    Optional name-value pairs for DataPipe configuration. Available options:
%
%    - data (numeric) -
%      Existing data to initialize a DataPipe with. Optional if data will
%      be appended later.
%
%    - maxSize (numeric) -
%      Row vector whose elements specify the max length for each dimension of
%      a dataset. Use `Inf` for unlimited growth along any dimension. Required 
%      if DATA is not provided. If you plan to append data later, maxSize
%      should be the final size of the dataset. If not provided, MAXSIZE is 
%      inferred from the DATA.
%
%    - axis (integer) -
%      Dimension to extend if appending data. Default is 1.
%
%    - dataType (string) -
%      Numerical data type for the dataset. Required if DATA is omitted. If 
%      DATA is provided and DATATYPE is not, the data type is inferred from the 
%      provided DATA.
%
%    - chunkSize (row vector) -
%      Size of chunks for HDF5 storage. Must be smaller than MAXSIZE.
%
%    - compressionLevel (integer) -
%      GZIP compression level. Default is 3.
%
%    - offset (row vector) -
%      Offset along dimensions where new data is appended. May be used to 
%      overwrite data.
%
%    - hasShuffle (logical) -
%      Whether to enable bit shuffling during compression. Default is false.
%      This is lossless and tends to save space without much cost to 
%      performance.
%
%    - filename (string) -
%      Path to an existing HDF5 file (for loading an existing dataset).
%      Requires path to be set (see below). filename and path should not be
%      used with any of the above options, which are for setting up a new 
%      DataPipe.
%
%    - path (string) -
%      Path within the HDF5 file to the existing dataset. Requires filename
%      to be set
%
% Output Arguments:
%  - dataPipe (types.untyped.DataPipe) - 
%    A DataPipe object configured for chunked, compressed HDF5 writing and
%    incremental data appending.
%
% Usage:
%  Example 1 - Create a data pipe with existing data::
%
%    dataPipe = types.untyped.DataPipe('data', myData);
%
%  Example 2 - Create a data pipe with unlimited growth along the first dimension::
%
%    dataPipe = types.untyped.DATAPIPE('maxSize', [Inf, 100], 'axis', 1);
%
%  Example 3 - Load a pre-existing dataset from an HDF5 file::
%
%    dataPipe = types.untyped.DATAPIPE('filename', 'data.h5', 'path', '/dataset1');

    properties (SetAccess = private)
        internal;
        filters;
    end
    
    properties (Dependent, SetAccess = private)
        isBound;
    end
    
    properties (Dependent)
        axis;
        offset;
        dataType;
        chunkSize;
        compressionLevel;
        hasShuffle;
    end
    
    methods
        %% Lifecycle
        function obj = DataPipe(options)
            arguments
                options.data
                options.maxSize
                options.dataType char
                options.axis (1,1) double {mustBeInteger, mustBePositive}
                options.offset (1,1) double {mustBeInteger, mustBeNonnegative}
                options.chunkSize
                options.compressionLevel (1,1) double {mustBeGreaterThanOrEqual(options.compressionLevel, -1)}
                options.hasShuffle (1,1) logical
                options.filters (1,:) types.untyped.datapipe.Property
                options.filename char
                options.path char
            end

            % Note: compression level is defaulted to ON. This is primarily 
            % for legacy support as we move into other filters.

            DEFAULTS = struct();
            DEFAULTS.axis = 1;
            DEFAULTS.offset = 0;
            DEFAULTS.compressionLevel = 3;
            DEFAULTS.hasShuffle = false;
            
            import types.untyped.datapipe.BoundPipe;
            import types.untyped.datapipe.BlueprintPipe;
            import types.untyped.datapipe.Configuration;
            import types.untyped.datapipe.properties.*;
            import types.untyped.datapipe.guessChunkSize;
            
            [hasFilename, hasPath] = obj.validateFilenameAndPath(options);

            if hasFilename && hasPath
                obj.internal = BoundPipe(options.filename, options.path);
                obj.showWarningIfOtherOptionsProvidedOnRead(options)
                return
            end

            % Validate/check provided options for missing or redundant fields
            obj.assertDataOrMaxSizeWasProvided(options)
            obj.showWarningForRedundantFilterOptions(options)

            % Add any default values to options if they were not provided
            options = obj.updateOptionsWithDefaultsIfMissing(options, DEFAULTS);

            % Infer maxSize if not provided.
            if ~isfield(options, 'maxSize')
                maxSize = size(options.data);
                maxSize(options.axis) = Inf;
            else
                maxSize = options.maxSize;
            end
            
            % Resolve dataType
            if ~isfield(options, 'data')
                assert(isfield(options, 'dataType'), ...
                    'NWB:DataPipe:MissingArguments', ...
                    '`dataType` must be provided if `data` is unset.')
                dataType = options.dataType;
            else
                if isfield(options, 'dataType')
                    warning('NWB:DataPipe:RedundantDataType',...
                        ['`datatype` parameter will be ignored in lieu of '...
                        'provided `data` value type.']);
                end
                dataType = class(options.data);
            end

            % Configure BlueprintPipe
            config = Configuration(maxSize);
            config.axis = options.axis;
            config.offset = options.offset;
            config.dataType = dataType;

            obj.internal = BlueprintPipe(config);

            % Configure chunking and compression
            if ~isfield(options, 'chunkSize')
                chunkSize = guessChunkSize(config.dataType, config.maxSize);
            else
                chunkSize = options.chunkSize;
            end
            obj.internal.setPipeProperties(Chunking(chunkSize));
            
            hasFilters = isfield(options, 'filters') && ~isempty(options.filters);
            
            if hasFilters
                filterCell = num2cell(options.filters);
                obj.internal.setPipeProperties(filterCell{:});
            else
                if -1 < options.compressionLevel
                    obj.internal.setPipeProperties(Compression(...
                        options.compressionLevel));
                end
                
                if logical(options.hasShuffle)
                    obj.internal.setPipeProperties(Shuffle());
                end
            end
            
            if isfield(options, 'data')
                obj.internal.data = options.data;
            end
        end
        
        %% SET/GET
        function tf = get.isBound(obj)
            tf = isa(obj.internal, 'types.untyped.datapipe.BoundPipe');
        end
        
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
            compressionClass = 'types.untyped.datapipe.properties.Compression';
            val = -1;
            if obj.internal.hasPipeProperty(compressionClass)
                val = obj.internal.getPipeProperty(compressionClass).level;
            end
        end
        
        function set.compressionLevel(obj, val)
            import types.untyped.datapipe.properties.Compression;
            validateattributes(val, {'numeric'}, {'scalar'}, 1);
            assert(-1 <= val, 'NWB:SetCompressionLevel:InvalidValue', ...
                'Compression Level cannot be less than -1.');
            compressionClass = 'types.untyped.datapipe.properties.Compression';
            if -1 == val
                obj.internal.removePipeProperty(compressionClass);
            else
                obj.internal.setPipeProperty(Compression(val));
            end
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
        
        %% API
        function data = load(obj, varargin)
            data = obj.internal.load(varargin{:});
        end
        
        function data = append(obj, data)
            obj.internal.append(data);
        end
        
        function refs = export(obj, fid, fullpath, refs)
            obj.internal = obj.internal.write(fid, fullpath);
        end
        
        %% Display
        function sz = size(obj, varargin)
            if isa(obj.internal, 'types.untyped.datapipe.BoundPipe')
                sz = obj.internal.dims(varargin{:});
            elseif isa(obj.internal, 'types.untyped.datapipe.BlueprintPipe')
                sz = size(obj.internal.data, varargin{:});
            else
                error('NWB:DataPipe:UnhandledPipe', ['Internal Datapipe of type `%s` does not '...
                    'have a handled size() method.'], class(obj.internal));
            end
        end
        
        %% Subsref
        function B = subsref(obj, S)
            CurrentSubRef = S(1);
            if strcmp(CurrentSubRef.type, '.')
                B = builtin('subsref', obj, S);
                return;
            end
            
            if isa(obj.internal, 'types.untyped.datapipe.BoundPipe')
                data = obj.internal.stub(CurrentSubRef.subs{:});
            elseif isa(obj.internal, 'types.untyped.datapipe.BlueprintPipe')
                data = obj.internal.data(CurrentSubRef.subs{:});
            else
                error('NWB:DataPipe:InvalidState', ...
                    'datapipe `internal` property is not a bound or a blueprint pipe.');
            end
            
            if isscalar(S)
                B = data;
            else
                B = subsref(data, S(2:end));
            end
        end
    end

    methods (Access = private) % Constructor helpers
        function [hasFilename, hasPath] = validateFilenameAndPath(~, options)
            hasFilename = isfield(options, 'filename');
            hasPath = isfield(options, 'path');

            ME = MException(...
                'NWB:DataPipe:MismatchedArguments', ...
                ['Both filename and path are required to create a bound ' ...
                'DataPipe. Only one of the above were specified.']);

            if xor(hasFilename, hasPath)
                throwAsCaller(ME)
            end

            assert(~xor(hasFilename, hasPath),...
                'NWB:DataPipe:MismatchedArguments',...
                ['Both filename and path are required to create a bound ' ...
                'DataPipe. Only one of the above were specified.']);
        end

        function showWarningIfOtherOptionsProvidedOnRead(~, options)
            providedOptions = string( fieldnames(options) );
            extraOptions = setdiff(providedOptions, {'filename', 'path'});

            if ~isempty(extraOptions)
                formatted = strjoin("    " + extraOptions, newline);
                warning('NWB:DataPipe:UnusedArguments',...
                    ['Other keyword arguments were added along with a valid '...
                    'filename and path.  Since the filename and path are valid, the '...
                    'following extra properties will be superseded by the '...
                    'configuration on file:\n%s'], formatted);
            end
        end

        function assertDataOrMaxSizeWasProvided(~, options)
            if ~isfield(options, 'maxSize') && ~isfield(options, 'data')
                ME = MException( ...
                    'NWB:DataPipe:MissingArguments', ...
                    ['Missing required input: either `maxSize` or `data` ', ...
                    'must be specified as a name-value pair.']);
                throwAsCaller(ME)
            end
        end

        function showWarningForRedundantFilterOptions(~, options)
        % showWarningForRedundantFilterOptions -
        %
        %   If 'filters' is provided, any values that are provided for 
        %   'compressionLevel' and/or 'hasShuffle' options will be ignored.

            hasFilters = isfield(options, 'filters') && ~isempty(options.filters);
            
            compressionLevelWasProvided = isfield(options, 'compressionLevel');
            shuffleWasProvided = isfield(options, 'hasShuffle');
            
            if hasFilters && (compressionLevelWasProvided || shuffleWasProvided)
                warning('NWB:DataPipe:FilterOverride', ...
                    ['`filters` keyword argument detected. This will ' ...
                    'override `compressionLevel` and `hasShuffle` keyword ' ...
                    'arguments. If you wish to use either `compressionLevel` ' ...
                    'or `hasShuffle`, please add their respective filter ' ...
                    'properties `types.untyped.datapipe.properties.Compression` ' ...
                    'and `types.untyped.datapipe.properties.Shuffle` to the ' ...
                    '`filters` properties array.']);
            end
        end

        function options = updateOptionsWithDefaultsIfMissing(~, options, defaults)
            defaultFields = fieldnames(defaults);
            for i = 1:numel(defaultFields)
                currentField = defaultFields{i};
                if ~isfield(options, currentField)
                    options.(currentField) = defaults.(currentField);
                end
            end
        end
    end
end
