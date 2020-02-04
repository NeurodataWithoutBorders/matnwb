classdef DataStub < handle
    %DATASTUB An abstracted `stub` of data which may point to a larger dataset.
    % The datastub should be a simple dataset type.
    properties (SetAccess = private)
        filename;
        path;
    end
    
    methods % lifecycle
        function obj = DataStub(filename, path)
            obj.filename = filename;
            obj.path = path;
        end
    end
    
    methods (Access = private)
        function Space = get_space(obj)
            File = h5.File.open(obj.filename);
            Dataset = h5.Dataset.open(File, obj.path);
            Space = Dataset.get_space();
        end
    end
    
    methods
        function dimensions = get_dims(obj)
            dimensions = obj.get_space().dims;
        end
        
        function nd = ndims(obj)
            nd = length(obj.get_dims());
        end
        
        function num = numel(obj)
            num = prod(obj.get_dims());
        end
        
        %can be called without arg, with H5ML.id, or (dims, offset, stride)
        function data = load_h5_style(obj, varargin)
            %LOAD_H5_STYLE  Read data from HDF5 dataset.
            %   DATA = LOAD_H5_STYLE() retrieves all of the data.
            %
            %   DATA = LOAD_H5_STYLE(SPACE) Loads subset of data defined by Space
            %
            %   DATA = LOAD_H5_STYLE(HYPERSLAB) reads a subset of data given an array
            %   of HyperSlabs.
            MSG_ID_CONTEXT = 'NWB:Untyped:DataStub:LoadH5Style:';
            
            File = h5.File(obj.filename);
            Dataset = h5.Dataset.open(File, obj.path);
            
            if isempty(varargin)
                Space = Dataset.get_space();
                if isa(Space, 'h5.space.SimpleSpace')
                    Space.select_all();
                end
            elseif isa(varargin{1}, 'h5.Space')
                Space = varargin{1};
            elseif isa(varargin{1}, 'h5.space.Hyperslab')
                Space = Dataset.get_space();
                Space.select(varargin{1});
            else
                error([MSG_ID_CONTEXT 'InvalidArgument'],...
                    'optional argument should either be a `h5.Space` or `h5.space.Hyperslab`');
            end
            
            data = Dataset.read('space', Space);
        end
        
        function data = load(obj, varargin)
            %LOAD  Read data from HDF5 dataset with syntax more similar to
            %core MATLAB
            %   DATA = LOAD() retrieves all of the data.
            %
            %   DATA = LOAD(INDEX) reads a subset of data based on MATLAB indices.
            %
            %   DATA = LOAD(START, END) reads a subset of data based on its start and
            %   end indices.
            % 
            %   DATA = LOAD(START, STRIDE, END) reads a subset of data based on its
            %   start indices, stride lengths, and end indices
            
            if isempty(varargin)
                data = obj.load_h5_style();
                return;
            end
            
            switch length(varargin)
                case 1
                    Space = obj.get_space();
                    indices = varargin{1};
                    Space.select(indices);
                    Selection = Space;
                case 2
                    startInd = varargin{1};
                    endInd = varargin{2};
                    shape = endInd - startInd + 1;
                    Selection = h5.space.Hyperslab(...
                        shape,...
                        'offset', startInd);
                case 3
                    startInd = varargin{1};
                    strideLength = varargin{2};
                    endInd = varargin{3};
                    shape = endInd - startInd + 1;
                    Selection = h5.space.Hyperslab(...
                        shape,...
                        'offset', startInd,...
                        'stride', strideLength);
                otherwise
                    error('NWB:Untyped:DataStub:InvalidNumArgs',...
                        ['Unexpected number of arguments.  Expects load(indices), '...
                        'load(start, end), or load(start, stride, end)']);
            end
            
            obj.load_h5_style(Selection);
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
    end
end