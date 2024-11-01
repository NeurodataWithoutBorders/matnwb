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
    
    methods
        function obj = DataStub(filename, path)
            validateattributes(filename, {'char', 'string'}, {'scalartext'} ...
                , 'types.untyped.DataStub', 'filename', 1);
            validateattributes(path, {'char', 'string'}, {'scalartext'} ...
                , 'types.untyped.DataStub', 'path', 2);
            obj.filename = char(filename);
            obj.path = char(path);
        end
        
        function sid = get_space(obj)
            fid = H5F.open(obj.filename);
            did = H5D.open(fid, obj.path);
            sid = H5D.get_space(did);
            H5D.close(did);
            H5F.close(fid);
        end
        
        function dims = get.dims(obj)
            sid = obj.get_space();
            [~, h5_dims, ~] = H5S.get_simple_extent_dims(sid);
            dims = fliplr(h5_dims);
            H5S.close(sid);
        end
        
        function nd = get.ndims(obj)
            nd = length(obj.dims);
        end

        function matType = get.dataType(obj)
            fid = H5F.open(obj.filename);
            did = H5D.open(fid, obj.path);
            tid = H5D.get_type(did);
            matType = io.getMatType(tid);
            H5D.close(did);
            H5F.close(fid);
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
                switch obj.dataType
                    case 'char'
                        % dataset strings are defaulted to cell arrays regardless of size
                        if iscellstr(data) && isscalar(data)
                            data = data{1};
                        elseif isstring(data)
                            data = convertStringsToChars(data);
                        end
                    case 'logical'
                        % data assumed to be cell array of enum string
                        % values.
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
            
            dims = obj.dims;
            rank = length(dims);
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
            dims = obj.dims;
            rank = length(dims);
            assert(rank >= expressionIndex, 'NWB:DataStub:InvalidEndIndex',...
                'Cannot index into index %d when max rank is %d', expressionIndex, rank);
            ind = dims(expressionIndex);
        end
    end
end