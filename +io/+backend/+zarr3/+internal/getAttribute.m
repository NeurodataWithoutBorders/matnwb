function [isFound, value] = getAttribute(attributes, name)
% getAttribute - Look up one attribute of a zarr-matlab node.
%
% [isFound, value] = getAttribute(attributes, name) reports whether the
% attributes of a zarr.Group or zarr.Array (its attrs property) contain the
% key name, and returns that attribute's value when they do ([] otherwise).
%
% zarr-matlab exposes attributes as a string -> cell dictionary, so that
% keys that are not valid MATLAB identifiers (".specloc", "_DTYPE",
% "_LINKS") survive exactly. A JSON object nested inside an attribute value
% decodes to the same kind of dictionary, so this also reads a field of
% such a value. Anything that is not a dictionary has no attributes.

    arguments
        attributes
        name (1,1) string
    end

    value = [];
    isFound = isa(attributes, "dictionary") && isKey(attributes, name);
    if isFound
        value = attributes{name};
    end
end
