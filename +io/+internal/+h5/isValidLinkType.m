function tf = isValidLinkType(linkType)
    VALID_TYPES = {'soft link', 'hard link', 'external link'};
    tf = any(strcmp(linkType, VALID_TYPES));
end
