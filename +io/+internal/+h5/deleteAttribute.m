function deleteAttribute(fileReference, objectLocation, attributeName)
% deleteAttribute - Delete the specified attribute from an NWB file

    arguments
        fileReference {io.internal.h5.mustBeH5FileReference}
        objectLocation (1,1) string
        attributeName (1,1) string
    end

    objectLocation = io.internal.h5.validateLocation(objectLocation);    

    % Open the HDF5 file in read-write mode
    [fileId, fileCleanupObj] = io.internal.h5.resolveFileReference(fileReference, "w"); %#ok<ASGLU>

    % Open the object (dataset or group)
    [objectId, objectCleanupObj] = io.internal.h5.openObject(fileId, objectLocation); %#ok<ASGLU>
    
    % Delete the attribute
    H5A.delete(objectId, attributeName);
end
