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
    properties (Access = private)
        dims_ double
        dataType_  {mustBeA(dataType_, ["char", "string", "struct"])} % Can be char (simple type) or struct (compound type descriptor)
    end
    
    methods
        function obj = DataStub(filename, path, dims, dataType)
            arguments
                filename (1,1) string
                path (1,1) string
                dims double = []
                dataType = string.empty  % Can be string/char or struct
            end
            obj.filename = char(filename);
            obj.path = char(path);
            obj.dims_ = dims;
            
            % Store dataType as-is: char for simple types, struct for compound types
            if isstring(dataType) || ischar(dataType)
                obj.dataType_ = char(dataType);
            else
                obj.dataType_ = dataType;  % Keep as struct for compound types
            end
        end
        
        function sid = get_space(obj) % Todo: private method
            fid = H5F.open(obj.filename);
            did = H5D.open(fid, obj.path);
            sid = H5D.get_space(did);
            H5D.close(did);
            H5F.close(fid);
        end
        
        function dims = get.dims(obj)
            if isempty(obj.dims_)
                sid = obj.get_space();
                [~, h5_dims, ~] = H5S.get_simple_extent_dims(sid);
                obj.dims_ = fliplr(h5_dims);
                H5S.close(sid);
            end
            dims = obj.dims_;
        end
        
        function nd = get.ndims(obj)
            nd = length(obj.dims);
        end

        function matType = get.dataType(obj)
            if isempty(obj.dataType_)
                fid = H5F.open(obj.filename);
                did = H5D.open(fid, obj.path);
                tid = H5D.get_type(did);
                
                obj.dataType_ = io.getMatType(tid);
                
                H5T.close(tid);
                H5D.close(did);
                H5F.close(fid);
            end
            matType = obj.dataType_;
        end
        
        %can be called without arg, with H5ML.id, or (dims, offset, stride)
        function data = load_h5_style(obj, varargin)
            %LOAD  Read data from HDF5 dataset.
            %   DATA = LOAD_H5_STYLE() retrieves all of the data.
            %
            %   DATA = LOAD_H5_STYLE(START,COUNT) reads a subset of data. START is
            %   the one-based index of the first element to be read.
            %   COUNT defines how many elements to read along each dimension.  If a
            %   particular element of COUNT is Inf, data is read until the end of the
            %   corresponding dimension.
            %
            %   DATA = LOAD_H5_STYLE(START,COUNT,STRIDE) reads a strided subset of
            %   data. STRIDE is the inter-element spacing along each
            %   data set extent and defaults to one along each extent.
            assert(length(varargin) ~= 1, 'NWB:DataStub:InvalidNumArguments',...
                'calling load_h5_style with a single space id is no longer supported.');
            
            data = h5read(obj.filename, obj.path, varargin{:});
                        
            if isstruct(data)
                % Compound type - data loaded as struct by h5read
                fid = H5F.open(obj.filename);
                did = H5D.open(fid, obj.path);
                fsid = H5D.get_space(did);
                data = H5D.read(did, 'H5ML_DEFAULT', fsid, fsid,...
                    'H5P_DEFAULT');
                data = io.parseCompound(did, data);
                H5S.close(fsid);
                H5D.close(did);
                H5F.close(fid);
            else
                % Non-compound types - apply type-specific post-processing
                
                % Validate: if dataType is struct, data must also be struct
                if isstruct(obj.dataType)
                    error('NWB:DataStub:InconsistentCompoundType', ...
                        ['DataStub has compound type descriptor, but loaded data is not a struct. '...
                        'This indicates a file corruption or type mismatch. '...
                        'Expected compound data for path: %s'], obj.path);
                end
                
                % Apply type-specific transformations for simple types
                switch obj.dataType
                    case 'char'
                        % dataset strings are defaulted to cell arrays regardless of size
                        if iscellstr(data) && isscalar(data)
                            data = data{1};
                        elseif isstring(data)
                            data = convertStringsToChars(data);
                        end
                    case 'logical'
                        % data assumed to be cell array of enum string values
                        data = strcmp('TRUE', data);
                end
            end
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
        
        refs = export(obj, fid, fullpath, refs);
        
        function B = subsref(obj, S)
            CurrentSubRef = S(1);
            if ~isscalar(obj) || strcmp(CurrentSubRef.type, '.')
                B = builtin('subsref', obj, S);
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
                B = data;
            else
                B = subsref(data, S(2:end));
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
end
