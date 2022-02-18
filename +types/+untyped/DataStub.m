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
        type;
    end
    
    methods
        function obj = DataStub(filename, path)
            obj.filename = filename;
            obj.path = path;
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

        function matType = get.type(obj)
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
            
            % dataset strings are defaulted to cell arrays regardless of size
            if iscellstr(data) && isscalar(data)
                data = data{1};
            elseif isstring(data)
                data = char(data);
            end
            
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
                % subsref, which apparantly poisons all calls in load() to
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
                validateattributes(START, {'numeric'}, {'vector', 'positive', 'numel', length(END)});
                validateattributes(STRIDE, {'numeric'}, {'vector', 'positive', 'numel', length(END)});
                assert(all(START <= END), 'NWB:DataStub:Load:InvalidStartIndex',...
                    'Start indices must be less than or equal to end indices.');
                selection = cell(size(END));
                for i = 1:length(selection)
                    selection{i} = START(i):STRIDE(i):END(i);
                end
                data = obj.load_mat_style(selection{:});
            end
        end
        
        function data = load_mat_style(obj, varargin)
            % LOAD_MAT_STYLE load data in matlab index format.
            % LOAD_MAT_STYLE(...) where each argument is an index into the dimension or ':'
            %   indicating load all of dimension. The dimension ordering is
            %   MATLAB, not HDF5 for this function.
            assert(length(varargin) <= obj.ndims, 'NWB:DataStub:Load:TooManyDimensions',...
                'Too many dimensions specified (got %d, expected %d)', length(varargin), obj.ndims);
            dims = obj.dims; %#ok<PROPLC>
            sid = obj.get_space();
            
            if isscalar(varargin) && ~ischar(varargin{1})
                orderedSelection = unique(varargin{1});
                
                if iscolumn(orderedSelection)
                    selectionDims = length(orderedSelection);
                    orderedSelection = orderedSelection .';
                else
                    selectionDims = fliplr(size(orderedSelection));
                end
                
                points = cell(length(dims), 1); %#ok<PROPLC>
                [points{:}] = ind2sub(dims, orderedSelection); %#ok<PROPLC>
                readSid = H5S.copy(sid);
                H5S.select_none(readSid);
                H5S.select_elements(readSid, 'H5S_SELECT_SET', cell2mat(flipud(points)) - 1);
                memSid = H5S.create_simple(length(selectionDims), selectionDims, selectionDims);
            else
                shapes = io.space.segmentSelection(varargin, dims); %#ok<PROPLC>
                [readSid, memSid] = io.space.getReadSpace(shapes, sid);
            end
            H5S.close(sid);
            
            % read data.
            fid = H5F.open(obj.filename);
            did = H5D.open(fid, obj.path);
            data = H5D.read(did, 'H5ML_DEFAULT', memSid, readSid, 'H5P_DEFAULT');
            H5D.close(did);
            H5F.close(fid);
            H5S.close(memSid);
            
            expectedSize = dims; %#ok<PROPLC>
            for i = 1:length(varargin)
                if ~ischar(varargin{i})
                    expectedSize(i) = length(varargin{i});
                end
            end
            
            if ischar(varargin{end})
                % dangling ':' where leftover dimensions are folded into
                % the last selection.
                selDimInd = length(varargin);
                expectedSize = [expectedSize(1:(selDimInd-1)) prod(dims(selDimInd:end))]; %#ok<PROPLC>
            else
                expectedSize = expectedSize(1:length(varargin));
            end
            
            if isscalar(varargin) && isscalar(expectedSize)
                % very special case where shape of the scalar indices determine the
                % shape of the output data for some reason.
                if 1 < sum(1 < dims) % is multi-dimensional data
                    if ~ischar(varargin{1}) && isrow(varargin{1})
                        expectedSize = [1 expectedSize];
                    else
                        expectedSize = [expectedSize 1];
                    end
                else
                    if dims(1) == 1 % probably a row
                        expectedSize = [1 expectedSize];
                    else % column
                        expectedSize = [expectedSize 1];
                    end
                end
            end
            
            selections = varargin;
            openSelInd = find(cellfun('isclass', selections, 'char'));
            for i = 1:length(openSelInd)
                selections{i} = 1:dims(i); %#ok<PROPLC>
            end
            data = reorderLoadedData(data, selections);
            data = reshape(data, expectedSize);
            
            function reordered = reorderLoadedData(data, selections)
                % dataset loading does not account for duplicate or unordered
                % indices so we have to re-order everything here.
                % we presume data is the indexed values of a unique(ind)
                if isempty(data)
                    reordered = data;
                    return;
                end
                
                indKey = cell(size(selections));
                isSelectionNormal = false(size(selections)); % that is, without duplicates or out of order.
                for i = 1:length(indKey)
                    indKey{i} = unique(selections{i});
                    isSelectionNormal = isequal(indKey{i}, selections{i});
                end
                if all(isSelectionNormal)
                    reordered = data;
                    return;
                end
                indKeyIndMax = cellfun('length', indKey);
                if isscalar(indKeyIndMax)
                    reordered = repmat(data(1), indKeyIndMax, 1);
                else
                    reordered = repmat(data(1), indKeyIndMax);
                end
                indKeyInd = ones(size(selections));
                while true
                    selInd = cell(size(selections));
                    for i = 1:length(selections)
                        selInd{i} = selections{i} == indKey{i}(indKeyInd(i));
                    end
                    indKeyIndArgs = num2cell(indKeyInd);
                    reordered(selInd{:}) = data(indKeyIndArgs{:});
                    indKeyIndNextInd = find(indKeyIndMax ~= indKeyInd, 1, 'last');
                    if isempty(indKeyIndNextInd)
                        break;
                    end
                    indKeyInd(indKeyIndNextInd) = indKeyInd(indKeyIndNextInd) + 1;
                    indKeyInd((indKeyIndNextInd+1):end) = 1;
                end
            end
        end
        
        function refs = export(obj, fid, fullpath, refs)
            %Check for compound data type refs
            src_fid = H5F.open(obj.filename);
            % if filenames are the same, then do nothing
            src_filename = H5F.get_name(src_fid);
            dest_filename = H5F.get_name(fid);
            if strcmp(src_filename, dest_filename)
                return;
            end
            
            src_did = H5D.open(src_fid, obj.path);
            src_tid = H5D.get_type(src_did);
            src_sid = H5D.get_space(src_did);
            ref_i = false;
            char_i = false;
            member_name = {};
            ref_tid = {};
            if H5T.get_class(src_tid) == H5ML.get_constant_value('H5T_COMPOUND')
                ncol = H5T.get_nmembers(src_tid);
                ref_i = false(ncol, 1);
                member_name = cell(ncol, 1);
                char_i = false(ncol, 1);
                ref_tid = cell(ncol, 1);
                refTypeConst = H5ML.get_constant_value('H5T_REFERENCE');
                strTypeConst = H5ML.get_constant_value('H5T_STRING');
                for i = 1:ncol
                    member_name{i} = H5T.get_member_name(src_tid, i-1);
                    subclass = H5T.get_member_class(src_tid, i-1);
                    subtid = H5T.get_member_type(src_tid, i-1);
                    char_i(i) = subclass == strTypeConst && ...
                        ~H5T.is_variable_str(subtid);
                    if subclass == refTypeConst
                        ref_i(i) = true;
                        ref_tid{i} = subtid;
                    end
                end
            end
            
            %manually load the data struct
            if any(ref_i)
                %This requires loading the entire table.
                %Due to this HDF5 library's inability to delete/update
                %dataset data, this is unfortunately required.
                ref_tid = ref_tid(~cellfun('isempty', ref_tid));
                data = H5D.read(src_did);
                
                refNames = member_name(ref_i);
                for i=1:length(refNames)
                    data.(refNames{i}) = io.parseReference(src_did, ref_tid{i}, ...
                        data.(refNames{i}));
                end
                
                strNames = member_name(char_i);
                for i=1:length(strNames)
                    s = data.(strNames{i}) .';
                    data.(strNames{i}) = mat2cell(s, ones(size(s,1),1));
                end
                
                io.writeCompound(fid, fullpath, data);
            else
                %copy data over and return destination
                ocpl = H5P.create('H5P_OBJECT_COPY');
                lcpl = H5P.create('H5P_LINK_CREATE');
                H5O.copy(src_fid, obj.path, fid, fullpath, ocpl, lcpl);
                H5P.close(ocpl);
                H5P.close(lcpl);
            end
            H5T.close(src_tid);
            H5S.close(src_sid);
            H5D.close(src_did);
            H5F.close(src_fid);
        end
        
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