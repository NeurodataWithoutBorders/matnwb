classdef Group < h5.interface.HasId & h5.interface.IsNamed & h5.interface.HasAttributes
    %GROUP HDF5 Group
    
    methods (Static)
        function Group = create(Parent, name)
            PLIST_ID = 'H5P_DEFAULT';
            
            Group = h5.Group(...
                H5G.create(Parent.get_id(), name,...
                PLIST_ID, PLIST_ID, PLIST_ID),...
                name);
        end
        
        function Group = open(Parent, name)
            Group = h5.Group(H5G.open(Parent.get_id(), name), name);
        end
    end
    
    properties (Access = private)
        id;
    end
    
    properties (SetAccess = private)
        name;
    end
    
    methods % lifecycle
        function obj = Group(id, name)
            obj.id = id;
            obj.name = name;
        end
        
        function delete(obj)
            H5G.close(obj.id);
        end
    end
    
    methods
        function add_link(obj, name, Link)
            assert(ischar(name), 'NWB:H5:Group:InvalidArgument',...
                'name must be a string.')
            isSoft = isa(Link, 'types.untyped.SoftLink');
            isExternal = isa(Link, 'types.untyped.ExternalLink');
            
            PROPLIST = 'H5P_DEFAULT';
            if isSoft
                H5L.create_soft(Link.path, obj.id, name, PROPLIST, PROPLIST);
            elseif isExternal
                H5L.create_external(Link.filename, Link.path, obj.id, name, PROPLIST, PROPLIST);
            else
                error('NWB:H5:Group:InvalidArgument',...
                'Link must be a types.untyped.SoftLink or types.untyped.ExternalLink');
            end
        end
        
        function delete_link(obj, name)
            assert(ischar(name), 'NWB:H5:Group:InvalidArgument',...
                'name must be a string.')
            H5L.delete(obj.id, name, 'H5P_DEFAULT');
        end
        
        function add_dataset(obj, name, data)
            h5.Dataset.create(obj, name, data);
        end
    end
    
    methods % HasId
        function id = get_id(obj)
            id = obj.id;
        end
    end

    methods % IsNamed
        function name = get_name(obj)
            name = obj.name;
        end
    end
end

