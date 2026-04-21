classdef (Sealed) DataStub < handle
%% DATASTUB a standin for readable data that has been written on disk.
% This class is sealed due to special subsref behavior breaking nargout
% expectations for most properties/methods.

    properties (SetAccess = protected)
        filename;
        path;
    end
    
    properties (Dependent, SetAccess = private)
        dims;
        ndims;
        dataType;
    end

    properties (Dependent, SetAccess = private, GetAccess = ?types.untyped.datapipe.BoundPipe)
        maxDims
    end

    properties (Access = private)
        lazyArray io.backend.base.LazyArray = io.backend.base.LazyArray.empty
    end
    
    methods
        function obj = DataStub(filename, path, dims, dataType, lazyArray)
            arguments
                filename (1,1) string
                path (1,1) string
                dims double = []
                dataType = []  % Can be string/char or struct
                lazyArray io.backend.base.LazyArray = io.backend.base.LazyArray.empty
            end
            obj.filename = char(filename);
            obj.path = char(path);

            if isempty(lazyArray)
                lazyArray = io.backend.BackendFactory.createLazyArray(...
                    filename, path, dims, dataType);
            end
            obj.lazyArray = lazyArray;
        end

        function dims = get.dims(obj)
            dims = obj.lazyArray.dims;
        end

        function maxDims = get.maxDims(obj)
            maxDims = obj.lazyArray.maxDims;
        end

        function nd = get.ndims(obj)
            nd = length(obj.dims);
        end

        function matType = get.dataType(obj)
            matType = obj.lazyArray.dataType;
        end
        
        %can be called without arg, with H5ML.id, or (dims, offset, stride)
        function data = load_h5_style(obj, varargin)
            data = obj.lazyArray.load_h5_style(varargin{:});
        end
        
        function data = load(obj, varargin)
            %LOAD  Read data from HDF5 dataset with syntax more similar to
            %core MATLAB
            %   DATA = LOAD() retrieves all of the data.
            %
            %   DATA = LOAD(INDEX)
            %
            %   DATA = LOAD(START,END) reads a subset of data.
            %   START and END are 1-based index indicating the beginning
            %   and end indices of the region to read
            %
            %   DATA = LOAD(START,STRIDE,END) reads a strided subset of
            %   data. STRIDE is the inter-element spacing along each
            %   data set extent and defaults to one along each extent.
            
            if isempty(varargin)
                data = obj.load_h5_style();
            elseif length(varargin) == 1
                % note: you cannot leverage subsref here because when
                % load() is called, it's calling the builtin version of
                % subsref, which apparently poisons all calls in load() to
                % use builtin subsref. We use the internal load_mat_style
                % to workaround this.
                data = obj.load_mat_style(varargin{1});
            else
                if length(varargin) == 2
                    START = varargin{1};
                    END = varargin{2};
                    STRIDE = ones(size(START));
                elseif length(varargin) == 3
                    START = varargin{1};
                    STRIDE = varargin{2};
                    END = varargin{3};
                end
                validateattributes(END, {'numeric'}, {'vector', 'positive'});
                validateattributes(START, {'numeric'}, ...
                    {'vector', 'positive', 'numel', length(END)});
                validateattributes(STRIDE, {'numeric'}, ...
                    {'vector', 'positive', 'numel', length(END)});
                assert(all(START <= END), 'NWB:DataStub:Load:InvalidStartIndex',...
                    'Start indices must be less than or equal to end indices.');
                selection = cell(size(END));
                for i = 1:length(selection)
                    selection{i} = START(i):STRIDE(i):END(i);
                end
                data = obj.load_mat_style(selection{:});
            end
        end

        data = load_mat_style(obj, varargin);
        
        refs = export(obj, writer, fullpath, refs);
        
        function varargout = subsref(obj, S)
            CurrentSubRef = S(1);
            if ~isscalar(obj) || strcmp(CurrentSubRef.type, '.')
                [varargout{1:nargout}] = builtin('subsref', obj, S);
                return;
            end
            
            rank = length(obj.dims);
            selectionRank = length(CurrentSubRef.subs);
            assert(rank >= selectionRank,...
                'NWB:DataStub:InvalidDimIndex',...
                'Cannot index into %d dimensions when max rank is %d',...
                selectionRank, rank);
            data = obj.load_mat_style(CurrentSubRef.subs{:});
            if isscalar(S)
                varargout = {data};
            else
                [varargout{1:nargout}] = subsref(data, S(2:end));
            end
        end
        
        function ind = end(obj, expressionIndex, numTotalIndices)
            % END is overloaded in order to support subsref indexing that
            % also may use end (i.e. datastub(1:end))
            if ~isscalar(obj)
                ind = builtin('end', obj, expressionIndex, numTotalIndices);
                return;
            end
            rank = length(obj.dims);
            assert(rank >= expressionIndex, 'NWB:DataStub:InvalidEndIndex',...
                'Cannot index into index %d when max rank is %d', expressionIndex, rank);
            ind = obj.dims(expressionIndex);
        end
        
        function tf = isCompoundType(obj)
            %ISCOMPOUNDTYPE Returns true if this DataStub represents a compound type
            dt = obj.dataType;  % Trigger lazy loading if needed
            tf = isstruct(dt);
        end
    end

    methods % Custom indexing
        function n = numArgumentsFromSubscript(obj, subs, indexingContext)
            if ~isscalar(subs) && strcmp(subs(1).type, '()')
                % Typical indexing pattern into compound data type, i.e
                % data(1:3).fieldName. Assume/expect one output.
                n = 1;
            else
                n = builtin('numArgumentsFromSubscript', obj, subs, indexingContext);
            end
        end
    end

    methods (Access = {?types.untyped.DataStub, ?types.untyped.datapipe.BoundPipe})
        function updateSize(obj)
        % updateSize - Should be called to initialize values or when dataset 
        % space is expanded
            obj.lazyArray.refreshSizeInfo();
        end
    end
end
