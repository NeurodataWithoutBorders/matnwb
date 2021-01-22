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
        
        %can be called without arg, with H5ML.id, or (dims, offset, stride)
        function data = load_h5_style(obj, varargin)
            %LOAD  Read data from HDF5 dataset.
            %   DATA = LOAD_H5_STYLE() retrieves all of the data.
            %
            %   DATA = LOAD_H5_STYLE(SPACE) Load data specified by HDF5 SPACE
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
            fid = [];
            did = [];
            if length(varargin) == 1
                fid = H5F.open(obj.filename);
                did = H5D.open(fid, obj.path);
                
                sid = varargin{1};
                numBlocks = H5S.get_select_hyper_nblocks(sid);
                % in event of multiple hyperslab selections, return as a cell array
                % format blocklist to cell array of region indices separated by
                % block
                bl = mat2cell(H5S.get_select_hyper_blocklist(sid, 0, numBlocks) .',...
                    repmat(2, 1, numBlocks), obj.ndims());
                
                data = cell(numBlocks,1);
                % go through each hyperslab selection and read data from H5D,
                % populating cell array of hyperslab selections
                for i=1:numBlocks
                    selsz = diff(bl{i})+1;
                    sizesid = H5S.create_simple(obj.ndims(), selsz, selsz);
                    H5S.select_hyperslab(sid, 'H5S_SELECT_SET',...
                        bl{i}(1,:), [], [], selsz);
                    data{i} = H5D.read(did,...
                        'H5ML_DEFAULT',...
                        sizesid,...
                        sid,...
                        'H5P_DEFAULT');
                end
                
                if numBlocks == 1
                    data = data{1};
                end
            else
                data = h5read(obj.filename, obj.path, varargin{:});
                
                % dataset strings are defaulted to cell arrays regardless of size
                if iscellstr(data) && isscalar(data)
                    data = data{1};
                elseif isstring(data)
                    data = char(data);
                end
            end
            
            if isstruct(data)
                if length(varargin) ~= 1
                    fid = H5F.open(obj.filename);
                    did = H5D.open(fid, obj.path);
                end
                fsid = H5D.get_space(did);
                data = H5D.read(did, 'H5ML_DEFAULT', fsid, fsid,...
                    'H5P_DEFAULT');
                data = io.parseCompound(did, data);
                H5S.close(fsid);
            end
            if ~isempty(fid)
                H5F.close(fid);
            end
            if ~isempty(did)
                H5D.close(did);
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
                region = misc.idx2h5(varargin{1}, obj.dims, 'preserve');
                sid = obj.get_space();
                H5S.select_none(sid);
                for i=1:length(region)
                    reg = region{i};
                    H5S.select_hyperslab(sid, 'H5S_SELECT_OR', reg(1,:),...
                        [], [], diff(reg, 1, 1)+1);
                end
                data = obj.load_h5_style(sid);
                H5S.close(sid);
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
                
                for i = 1:length(END)
                    if strcmp(END(i), 'end')
                        count(i) = Inf;
                    else
                        count(i) = floor((END(i) - START(i)) / STRIDE(i) + 1);
                    end
                end
                if length(START) == 1
                    data = obj.load_h5_style(double(START), double(count), double(STRIDE));
                else
                    data = obj.load_h5_style(START, count, STRIDE);
                end
            end
        end
        
        function data = load_mat_style(obj, varargin)
            % LOAD_MAT_STYLE load data in matlab index format.
            % LOAD_MAT_STYLE(...) where each argument is an index into the dimension or ':'
            %   indicating load all of dimension. The dimension ordering is
            %   MATLAB, not HDF5 for this function.
            assert(length(varargin) <= obj.ndims, 'MatNWB:DataStub:Load:TooManyDimensions',...
                'Too many dimensions specified (got %d, expected %d)', length(varargin), obj.ndims);
            dims = obj.dims;
            rank = length(dims);
            for i = 1:length(varargin)
                if ischar(varargin{i})
                    continue;
                end
                validateattributes(varargin{i}, {'numeric'}, {'vector', '<=', dims(i)});
            end
            shapes = getShapes(varargin, dims);
            
            sid = obj.get_space();
            H5S.select_none(sid); % reset selection on file.
            shapeInd = ones(1, rank);
            shapeIndEnd = cellfun('length', shapes);
            while true
                start = zeros(1, rank);
                stride = ones(1, rank);
                count = ones(1, rank);
                block = ones(1, rank);
                for i = 1:length(shapes)
                    Selection = shapes{i}{shapeInd};
                    [start(i), stride(i), count(i), block(i)] = Selection.getSpaceSpec();
                end
                H5S.select_hyperslab(sid, 'H5S_SELECT_OR', start, stride, count, block);
                
                if isequal(shapeInd, shapeIndEnd)
                    break;
                end
                
                % bubble up and iterate once.
                trickleDownInd = length(shapeInd) + 1; % default to coerce empty array if at the end.
                for i = fliplr(1:length(shapeInd))
                    if shapeInd(i) < shapeIndEnd(i)
                        shapeInd(i) = shapeInd(i) + 1;
                        trickleDownInd = i + 1;
                        break;
                    end
                end
                % THEN, go back down and RESET all subsequent iterations
                for j = trickleDownInd:length(shapeInd)
                    shapeInd(j) = 1;
                end
            end
            
            data = obj.load_h5_style(sid);
            if iscell(data)
                selDims = dims(1:2);
                for i = 1:2
                    if ~ischar(varargin{i})
                        selDims(i) = length(varargin{i});
                    end
                end
                data = cell2mat(reshape(data, selDims));
            end
            H5S.close(sid);
            
            function shapes = getShapes(selections, dims)
                rank = length(dims);
                shapes = cell(1, rank); % cell array of cell arrays of shapes
                isDanglingGroup = ischar(selections{end});
                for i = 1:rank
                    if i > length(selections) && ~isDanglingGroup % select a scalar element.
                        shapes{i} = {types.untyped.datastub.shape.Point(0)};
                    elseif (i > length(selections) && isDanglingGroup)...
                            || ischar(selections{i})
                        % select the whole dimension
                        % dims(i) - 1 because block represents 0-indexed
                        % inclusive stop. The Block.length == dims(i)
                        shapes{i} = {types.untyped.datastub.shape.Block('stop', dims(i) - 1)};
                    else
                        % break the selection into range/point pieces
                        % per dimension.
                        % also convert to 0-indexed format.
                        shapes{i} = types.untyped.datastub.findShapes(selections{i} - 1);
                    end
                end
                shapes = fliplr(shapes); % convert to HDF5 dimension ordering.
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
                'MatNWB:DataStub:InvalidDimIndex',...
                'Cannot index into %d dimensions when max rank is %d',...
                selectionRank, rank);
            data = obj.load_mat_style(CurrentSubRef.subs{:});
            if ischar(CurrentSubRef.subs{end})
                % dangling ':' where leftover dimensions are folded into
                % the last selection.
                selDimInd = length(CurrentSubRef.subs);
                selDims = zeros(1, selDimInd);
                for i = 1:(selDimInd-1)
                    if ischar(CurrentSubRef.subs{i})
                        selDims(i) = dims(i);
                    else
                        selDims(i) = length(CurrentSubRef.subs{i});
                    end
                end
                selDims(end) = prod(dims(selDimInd:end));
                data = reshape(data, selDims);
            end
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
            assert(rank >= expressionIndex, 'MatNwb:DataStub:InvalidEndIndex',...
                'Cannot index into index %d when max rank is %d', expressionIndex, rank);
            ind = dims(expressionIndex);
        end
    end
end