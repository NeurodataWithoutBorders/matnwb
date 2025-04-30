function [fileId, fileCleanupObj] = openFile(fileName, permission)
% openFile Opens an HDF5 file with the specified permissions and ensures cleanup.
%
%   [fileId, fileCleanupObj] = io.internal.h5.openFile(fileName) opens the HDF5 
%   file specified by fileName in read-only mode ('r') by default.
%
%   [fileId, fileCleanupObj] = io.internal.h5.openFile(fileName, permission) 
%   opens the HDF5 file specified by fileName with the access mode defined by 
%   permission. 
%
%   Input Arguments:
%       fileName   - A string or character vector specifying the path to the 
%                    HDF5 file. This must be a .h5 or .nwb file.
%
%       permission - (Optional) A scalar string specifying the file access mode.
%                    Valid values are "r" for read-only (default) and "w" for 
%                    read-write.
%
%   Output Arguments:
%       fileId         - The file identifier returned by H5F.open, used to 
%                        reference the open file.
%
%       fileCleanupObj - A cleanup object (onCleanup) that ensures the file is 
%                        closed automatically when fileCleanupObj goes out of 
%                        scope.
%
%   Example:
%       [fid, cleanupObj] = io.internal.h5.openFile("data.h5", "w");
%       % Use fid for file operations.
%       % When cleanupObj is cleared or goes out of scope, the file is 
%       % automatically closed.

    arguments
        fileName {io.internal.h5.mustBeH5File}
        permission (1,1) string {mustBeMember(permission, ["r", "w"])} = "r"
    end
    
    switch permission
        case "r"
            accessFlag = 'H5F_ACC_RDONLY';
        case "w"
            accessFlag = 'H5F_ACC_RDWR';
    end
    fileId = H5F.open(fileName, accessFlag, 'H5P_DEFAULT');
    fileCleanupObj = onCleanup(@(fid) H5F.close(fileId));
end
