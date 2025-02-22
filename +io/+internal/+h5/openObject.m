function [objectId, objectCleanupObj] = openObject(fileId, objectLocation)
% openObject Opens an HDF5 object at given location and ensures cleanup.

    arguments
        fileId {mustBeA(fileId, "H5ML.id")}
        objectLocation (1,1) string
    end
    
    % Open the object (dataset or group)
    objectLocation = io.internal.h5.validateLocation(objectLocation);
    objectId = H5O.open(fileId, objectLocation, 'H5P_DEFAULT');
    objectCleanupObj = onCleanup(@(oid) H5O.close(objectId));
end
