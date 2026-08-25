function writeLink(fileId, linkPath, linkType, targetPath, targetFilename)
% writeLink - Create a soft or external link in an HDF5 file.
%
% writeLink(fileId, linkPath, "soft", targetPath) creates a link at
% linkPath resolving to targetPath in the same file.
%
% writeLink(fileId, linkPath, "external", targetPath, targetFilename)
% creates a link at linkPath resolving to targetPath inside
% targetFilename.
%
% An existing link at linkPath is left alone when it already points at the
% requested target, and replaced otherwise. matnwb exports an object whose
% link target is not resolvable yet a second time, once the target exists
% (see NwbFile.resolveReferences), so re-writing the same link is routine
% rather than a conflict.
%
% Errors with NWB:WriteLink:PathOccupiedByNode when a group or dataset
% already occupies linkPath, rather than deleting it.

    arguments
        fileId
        linkPath (1,:) char
        linkType (1,1) string {mustBeMember(linkType, ["soft", "external"])}
        targetPath (1,:) char
        targetFilename (1,:) char = ''
    end

    propertyListId = 'H5P_DEFAULT';
    if H5L.exists(fileId, linkPath, propertyListId)
        existingType = readExistingLinkType(fileId, linkPath, propertyListId);
        assert(existingType ~= "none", 'NWB:WriteLink:PathOccupiedByNode', ...
            ['A group or dataset already exists at "%s", so a %s link ', ...
            'cannot be written there. Remove the existing node, or write ', ...
            'the link at a different location.'], linkPath, linkType);
        if isMatchingLink(fileId, linkPath, propertyListId, existingType, ...
                linkType, targetPath, targetFilename)
            return
        end
        H5L.delete(fileId, linkPath, propertyListId);
    end

    if linkType == "soft"
        H5L.create_soft(targetPath, fileId, linkPath, propertyListId, propertyListId);
    else
        H5L.create_external(targetFilename, targetPath, fileId, linkPath, ...
            propertyListId, propertyListId);
    end
end

function existingType = readExistingLinkType(fileId, linkPath, propertyListId)
% readExistingLinkType - "soft", "external", or "none" for a non-link node.
%
% A group or dataset is a hard link, which reports as "none" here: it is a
% node occupying the path rather than a link that could be compared or
% replaced.

    linkInfo = H5L.get_info(fileId, linkPath, propertyListId);
    if linkInfo.type == H5ML.get_constant_value('H5L_TYPE_SOFT')
        existingType = "soft";
    elseif linkInfo.type == H5ML.get_constant_value('H5L_TYPE_EXTERNAL')
        existingType = "external";
    else
        existingType = "none";
    end
end

function isMatch = isMatchingLink(fileId, linkPath, propertyListId, ...
        existingType, linkType, targetPath, targetFilename)
% isMatchingLink - Whether the link already present is the one requested.
%
% H5L.get_val returns {targetPath} for a soft link and
% {targetFilename, targetPath} for an external one. It is only valid for a
% symbolic link, so the caller has already excluded a non-link node.

    isMatch = false;
    if existingType ~= linkType
        return
    end

    existingValue = H5L.get_val(fileId, linkPath, propertyListId);
    if linkType == "soft"
        isMatch = strcmp(existingValue{1}, targetPath);
    else
        isMatch = strcmp(existingValue{1}, targetFilename) ...
            && strcmp(existingValue{2}, targetPath);
    end
end
