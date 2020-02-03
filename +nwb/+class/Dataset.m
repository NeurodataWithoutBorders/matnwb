classdef Dataset < nwb.Class
    %DATASET this class is a typed Dataset.  It has a special `data` field which will
    % hold the primary data in this dataset.  All properties will be converted to
    % H5 Attributes.  No elision exists.
    
    properties (SetAccess = private)
        name;
        parent = nwb.class.Dataset.empty;
        attributes = nwb.class.Property.empty;
    end
    
    methods % Lifecycle
        
    end
    
    methods % set/get
    end
    
    methods % Writable
        function write(obj, file_id)
        end
    end
    
    methods % Class
        function name = get_name(obj)
        end
        
        function dependencies = get_dependencies(obj)
        end
        
        function Props = get_properties(obj)
        end
    end
end

