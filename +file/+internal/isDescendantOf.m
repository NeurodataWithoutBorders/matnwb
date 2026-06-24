function tf = isDescendantOf(name, namespace, targetAncestorName)
%isDescendantOf Check if a type inherits from an ancestor type.

    tf = false;

    if strcmp(name, targetAncestorName)
        tf = true;
        return
    end

    ancestry = namespace.getRootBranch(name);
    for iAncestor = 1:length(ancestry)
        parentRaw = ancestry{iAncestor};
        typeDefIndex = isKey(parentRaw, namespace.TYPEDEF_KEYS);
        currentAncestorName = parentRaw(namespace.TYPEDEF_KEYS{typeDefIndex});
        tf = tf || strcmp(currentAncestorName, targetAncestorName);
    end
end
