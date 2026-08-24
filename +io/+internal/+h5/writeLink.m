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

    arguments
        fileId
        linkPath (1,:) char
        linkType (1,1) string {mustBeMember(linkType, ["soft", "external"])}
        targetPath (1,:) char
        targetFilename (1,:) char = ''
    end

    plist = 'H5P_DEFAULT';
    if H5L.exists(fileId, linkPath, plist)
        if isMatchingLink(fileId, linkPath, plist, linkType, targetPath, targetFilename)
            return
        end
        H5L.delete(fileId, linkPath, plist);
    end

    if linkType == "soft"
        H5L.create_soft(targetPath, fileId, linkPath, plist, plist);
    else
        H5L.create_external(targetFilename, targetPath, fileId, linkPath, plist, plist);
    end
end

function tf = isMatchingLink(fileId, linkPath, plist, linkType, targetPath, targetFilename)
% isMatchingLink - Whether the link already present is the one requested.
%
% H5L.get_val returns {targetPath} for a soft link and
% {targetFilename, targetPath} for an external one. A path that holds a
% group or dataset rather than a link is not a match, so it is replaced.

    tf = false;
    linkInfo = H5L.get_info(fileId, linkPath, plist);
    isSoft = linkInfo.type == H5ML.get_constant_value('H5L_TYPE_SOFT');
    isExternal = linkInfo.type == H5ML.get_constant_value('H5L_TYPE_EXTERNAL');

    if linkType == "soft" && isSoft
        existingValue = H5L.get_val(fileId, linkPath, plist);
        tf = strcmp(existingValue{1}, targetPath);
    elseif linkType == "external" && isExternal
        existingValue = H5L.get_val(fileId, linkPath, plist);
        tf = strcmp(existingValue{1}, targetFilename) ...
            && strcmp(existingValue{2}, targetPath);
    end
end
