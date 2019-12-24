classdef Attribute < h5.HasId
    %ATTRIBUTE HDF5 attribute
    
    methods (Static)
        function Attribute = create(Parent, name, Type, Space)
            assert(isa(Parent, 'h5.HasId'),...
                'NWB:H5:Attribute:InvalidArgument', 'Parent must have an ID');
            assert(isa(Type, 'h5.Type'),...
                'NWB:H5:Attribute:InvalidArgument', 'Type must be a h5.Type');
            assert(isa(Space, 'h5.Space'),...
                'NWB:H5:Attribute:InvalidArgument', 'Space must be a h5.Space');
            
            PROPLIST_ID = 'H5P_DEFAULT';
            Attribute = h5.Attribute(...
                H5A.create(Parent.get_id(), name, Type.get_id(), Space.get_id(),...
                PROPLIST_ID, PROPLIST_ID));
        end
        
        function Attribute = open(Parent, name)
            assert(isa(Parent, 'h5.HasId'),...
                'NWB:H5:Attribute:InvalidArgument', 'Parent must have an ID');
            
            PROPLIST_ID = 'H5P_DEFAULT';
            Attribute = h5.Attribute(H5A.open_by_name(Parent.get_id(), name,...
                PROPLIST_ID, PROPLIST_ID));
        end
    end
    
    properties (Access = private)
        id;
    end
    
    properties (GetAccess = private, Dependent)
        type;
    end
    
    methods % lifecycle
        function obj = Attribute(id)
            obj.id = id;
        end
        
        function delete(obj)
            H5A.close(obj.id);
        end
    end
    
    methods % set/get
        function Type = get.type(obj)
            Type = h5.Type(H5A.get_type(obj.id));
        end
    end
    
    methods
        function write(obj, data)
            H5A.write(obj.id, obj.type.get_id(), data);
        end
        
        function data = read(obj)
            data = H5A.read(obj.id, 'H5ML_DEFAULT');
        end
    end
    
    methods % h5.HasId
        function id = get_id(obj)
            id = obj.id;
        end
    end
end

