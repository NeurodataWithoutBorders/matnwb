function [groupId, groupCleanupObj] = openGroup(fileId, h5Location)
% openGroup Opens an HDF5 group at given location and ensures cleanup.

    arguments
        fileId {mustBeA(fileId, "H5ML.id")}
        h5Location (1,1) string
    end
    
    % Open the specified location (group)
    groupLocation = io.internal.h5.validateLocation(h5Location);    
    groupId = H5G.open(fileId, groupLocation);
    groupCleanupObj = onCleanup(@(gid) H5G.close(groupId));
end
