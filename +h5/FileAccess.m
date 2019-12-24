classdef FileAccess
    %FILEACCESS file access primitive for use with h5.File
    
    properties
        mode;
    end
    
    methods
        function obj = FileAccess(mode)
            obj.mode = mode;
        end
    end
    
    enumeration
        ReadOnly('H5F_ACC_RDONLY');
        ReadWrite('H5F_ACC_RDWR');
    end
end

