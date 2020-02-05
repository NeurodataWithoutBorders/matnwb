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
        
        function MissingViews = export(obj, Parent, name)
            MissingViews = containers.Map.empty;
            if strcmp(obj.filename, Parent.get_file().filename)
                return;
            end
            
            %copy data over and return destination
            Source_File = h5.File.open(obj.filename);
            ocpl = H5P.create('H5P_OBJECT_COPY');
            lcpl = H5P.create('H5P_LINK_CREATE');
            H5O.copy(Source_File.get_id(), obj.path,...
                Parent.get_id(), name, ocpl, lcpl);
            H5P.close(ocpl);
            H5P.close(lcpl);
        end
    end
end