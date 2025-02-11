function deleteGroup(fileReference, groupLocation)
% deleteGroup - Delete the specified group from an NWB file
%
% NB NB NB: Deleting groups & datasets from an HDF5 file does not free up space
%
% HDF5 files use a structured format to store data in hierarchical groups and 
% datasets. Internally, the file maintains a structure similar to a filesystem, 
% with metadata pointing to the actual data blocks.
% 
% Implication: When you delete a group or dataset in an HDF5 file, the metadata 
% entries for that group or dataset are removed, so they are no longer accessible.
% However, the space previously occupied by the actual data is not reclaimed or 
% reused by default. This is because HDF5 does not automatically reorganize or 
% compress the file when items are deleted.

    arguments
        fileReference {io.internal.h5.mustBeH5FileReference}
        groupLocation (1,1) string
    end

    groupLocation = io.internal.h5.validateLocation(groupLocation);    

    % Open the HDF5 file in read-write mode
    [fileId, fileCleanupObj] = io.internal.h5.resolveFileReference(fileReference, "w"); %#ok<ASGLU>
            
    [objectId, objectCleanupObj] = io.internal.h5.openObject(fileId, groupLocation); %#ok<ASGLU>
    objInfo = H5O.get_info(objectId);
    clear objectCleanupObj
    
    if objInfo.type == H5ML.get_constant_value('H5O_TYPE_GROUP')
        % Delete the group
        H5L.delete(fileId, groupLocation, 'H5P_DEFAULT');
    else
        error('NWB:DeleteGroup:NotAGroup', ...
            'The h5 object in location "%s" is not a group', groupLocation)
    end
end
