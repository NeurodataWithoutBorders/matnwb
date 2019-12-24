classdef File < h5.HasId
    %FILE HDF5 file
    
    methods (Static)
        function File = create(filename)
            PLIST_ID = 'H5P_DEFAULT';
            File = h5.File(...
                H5F.create(filename, 'H5F_ACC_EXCL', PLIST_ID, PLIST_ID));
        end
        
        function File = open(filename, Access)
            assert(isa(Access, 'h5.FileAccess'),...
                'NWB:H5:File:InvalidArgument',...
                'File Access must use the h5.FileAccess enum.');
            File = h5.File(...
                H5F.open(filename, Access.mode, 'H5P_DEFAULT'));
        end
    end
    
    properties
        id;
    end
    
    properties (GetAccess = private, Dependent)
        name;
    end
    
    methods % lifecycle
        function obj = File(id)
            obj.id = id;
        end
        
        function delete(obj)
            H5F.close(obj.id);
        end
    end
    
    methods % set/get
        function name = get.name(obj)
            name = H5F.get_name(obj.id);
        end
    end
    
    methods % h5.HasId
        function id = get_id(obj)
            id = obj.id;
        end
    end
end

