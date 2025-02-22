function namespaceNames = listEmbeddedSpecNamespaces(fileReference)

    arguments
        fileReference {io.internal.h5.mustBeH5FileReference}
    end

    [fileId, fileCleanupObj] = io.internal.h5.resolveFileReference(fileReference); %#ok<ASGLU>
    
    specLocation = io.spec.internal.readEmbeddedSpecLocation(fileId);
    namespaceNames = io.internal.h5.listGroupNames(fileId, specLocation);
end
