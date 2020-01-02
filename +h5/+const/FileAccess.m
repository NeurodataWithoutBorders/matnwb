classdef FileAccess < h5.interface.IsConstant
    %FILEACCESS file access primitive for use with h5.File
    
    enumeration
        ReadOnly('H5F_ACC_RDONLY');
        ReadWrite('H5F_ACC_RDWR');
    end
end

