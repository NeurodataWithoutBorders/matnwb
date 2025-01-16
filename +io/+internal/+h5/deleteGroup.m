function deleteGroup(fileReference, groupLocation)
% deleteGroup - Delete the specified group from an NWB file

    arguments
        fileReference {io.internal.h5.mustBeH5FileReference}
        groupLocation (1,1) string
    end

    groupLocation = io.internal.h5.validateLocation(groupLocation);    

    % Open the HDF5 file in read-write mode
    [fileId, fileCleanupObj] = io.internal.h5.resolveFileReference(fileReference, "w"); %#ok<ASGLU>
    
    % Delete the group
    H5L.delete(fileId, groupLocation, 'H5P_DEFAULT');
end
