function [h5FileId, fileCleanupObj] = resolveFileReference(fileReference, permission)
% resolveFileReference - Resolve a file reference to a H5 File ID.
%
% Utility method to resolve a file reference, which can be either a
% filepath or a file id for a h5 file.
% 
% The returned value will always be a file ID. This allows functions that
% does operations on h5 files to receive either a file path or a file id
%
% Note: If the file reference is a file ID for an open file, the permission 
% might be different than the provided/requested permission. 

    arguments
        fileReference {io.internal.h5.mustBeH5FileReference}
        permission (1,1) string {mustBeMember(permission, ["r", "w"])} = "r"
    end
    
    if isa(fileReference, "char") || isa(fileReference, "string")
        % Need to open the file
        if isfile(fileReference)
            [h5FileId, fileCleanupObj] = io.internal.h5.openFile(fileReference, permission);
        else
            error('File "%s" does not exist', fileReference)
        end
    else
        h5FileId = fileReference;
        % If the file is already open, we are not responsible for closing it
        fileCleanupObj = [];
    end
end
