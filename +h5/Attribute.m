classdef Attribute < h5.interface.HasId...
        & h5.interface.IsNamed...
        & h5.interface.IsHdfData
    %ATTRIBUTE HDF5 attribute
    
    methods (Static)
        function Attribute = create(Parent, name, data)
            assert(isa(Parent, 'h5.HasId'),...
                'NWB:H5:Attribute:InvalidArgument', 'Parent must have an ID');
            
            PROPLIST_ID = 'H5P_DEFAULT';
            Type = h5.Type.deriveFromMatlab(class(data));
            Space = h5.Space.deriveFromMatlab(Type, size(data));
            aid = H5A.create(Parent.get_id(), name, Type.get_id(), Space.get_id(),...
                PROPLIST_ID, PROPLIST_ID);
            Attribute = h5.Attribute(aid, name);
            Attribute.write(data);
        end
        
        function Attribute = open(Parent, name)
            assert(isa(Parent, 'h5.HasId'),...
                'NWB:H5:Attribute:InvalidArgument', 'Parent must have an ID');
            
            PROPLIST_ID = 'H5P_DEFAULT';
            Attribute = h5.Attribute(H5A.open_by_name(Parent.get_id(), name,...
                PROPLIST_ID, PROPLIST_ID));
        end
    end
    
    properties (SetAccess = private, Dependent)
        name;
    end
    
    properties (Access = private)
        id;
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
        function name = get.name(obj)
            name = obj.get_name();
        end
    end
    
    methods % HasId
        function id = get_id(obj)
            id = obj.id;
        end
    end
    
    methods (Access = protected) % HasSpace
        function id = get_space_id(obj)
            id = H5A.get_space(obj.id);
        end
    end
    
    methods (Access = protected) % HasType
        function type_id = get_type_id(obj)
            type_id = H5A.get_type(obj.id);
        end
    end
    
    methods % IsHdfData
        function write(obj, data, varargin)
            H5A.write(obj.id, obj.type.get_id(), obj.serialize(data));
        end
        
        function data = read(obj, varargin)
            data = H5A.read(obj.id, 'H5ML_DEFAULT');
        end
    end
    
    methods % IsNamed
        function name = get_name(obj)
            name = H5A.get_name(obj.id);
        end
    end
end

