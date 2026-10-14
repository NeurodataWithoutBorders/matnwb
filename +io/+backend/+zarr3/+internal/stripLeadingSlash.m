function strippedPath = stripLeadingSlash(nodePath)
% stripLeadingSlash - Remove a single leading '/' from a node path.

    strippedPath = regexprep(char(nodePath), '^/', '');
end
