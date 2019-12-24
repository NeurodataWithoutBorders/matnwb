classdef Dataset < h5.HasId
    %DATASET HDF5 Dataset
    
    methods (Static)
        function Dataset = create(Parent, name, Type, Space, varargin)
            assert(isa(Parent, 'h5.HasId'),...
                'NWB:H5:Dataset:InvalidArgument', 'Parent must have an ID');
            assert(isa(Type, 'h5.Type'),...
                'NWB:H5:Dataset:InvalidArgument', 'Type must be a h5.Type');
            assert(isa(Space, 'h5.Space'),...
                'NWB:H5:Dataset:InvalidArgument', 'Space must be a h5.Space');
            
            Dataset = h5.Dataset(H5D.create(Parent.get_id(), name,...
                Type.get_id(), Space.get_id(), lcpl_id, dcpl_id, dapl_id));
        end
        
        function Dataset = open(Parent, name)
            assert(isa(Parent, 'h5.HasId'),...
                'NWB:H5:Dataset:InvalidArgument', 'Parent must have an ID');
            Dataset = h5.Dataset(H5D.open(Parent.get_id(), name));
        end
    end
    
    properties (Access = private)
        id;
    end
    
    properties (SetAccess = private, Dependent)
        space;
        type;
    end
    
    methods % lifecycle
        function obj = Dataset(id)
            obj.id = id;
        end
        
        function delete(obj)
            H5D.close(obj.id);
        end
    end
    
    methods % set/get
        function Space = get.space(obj)
           Space = H5.Space(H5D.get_space(obj.id)); 
        end
        
        function Type = get.type(obj)
            Type = H5.Type(H5D.get_type(obj.id));
        end
    end
    
    methods
        function write(obj, data)
            PLIST_ID = 'H5P_DEFAULT';
            Type = obj.type;
            Space = obj.space;
            H5D.write(obj.id,...
                Type.get_id(), Space.get_id(), Space.get_id(), PLIST_ID, data);
        end
        
        function data = read(obj)
            data = H5D.read(obj.id);
        end
    end
    
    methods % h5.HasId
        function id = get_id(obj)
            id = obj.id;
        end
    end
end