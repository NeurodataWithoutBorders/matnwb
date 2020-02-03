classdef HasSubObjects < h5.interface.HasId
    %HASSUBOBJECTS This class can contain Links, Datasets, and Groups
    
    methods
        function add_link(obj, name, Link)
            assert(ischar(name), 'NWB:H5:Group:InvalidArgument',...
                'name must be a string.')
            isSoft = isa(Link, 'types.untyped.SoftLink');
            isExternal = isa(Link, 'types.untyped.ExternalLink');
            
            pid = 'H5P_DEFAULT';
            if isSoft
                H5L.create_soft(Link.path, obj.get_id(), name, pid, pid);
            elseif isExternal
                H5L.create_external(Link.filename, Link.path, obj.get_id(), name, pid, pid);
            else
                error('NWB:H5:Group:InvalidArgument',...
                'Link must be a types.untyped.SoftLink or types.untyped.ExternalLink');
            end
        end
        
        function delete_link(obj, name)
            assert(ischar(name), 'NWB:H5:Group:InvalidArgument',...
                'name must be a string.')
            H5L.delete(obj.get_id(), name, 'H5P_DEFAULT');
        end
        
        function add_dataset(obj, varargin)
            h5.Dataset.create(obj, varargin{:});
        end
        
        function add_compound(obj, varargin)
            h5.CompoundDataset.create(obj, varargin{:});
        end
        
        function add_group(obj, varargin)
            h5.Group.create(obj, varargin{:});
        end
        
        function SubObjects = get_subobjects(obj)
            
        end
    end
end