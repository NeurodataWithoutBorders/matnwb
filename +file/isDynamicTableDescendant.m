function tf = isDynamicTableDescendant(name, namespace)
%ISDYNAMICTABLEDESCENDANT Check if a type inherits from DynamicTable.

    tf = false;

    if strcmp(name, 'DynamicTable')
        tf = true;
        return
    end

    ancestry = namespace.getRootBranch(name);
    for iAncestor = 1:length(ancestry)
        parentRaw = ancestry{iAncestor};
        typeDefIndex = isKey(parentRaw, namespace.TYPEDEF_KEYS);
        ancestorName = parentRaw(namespace.TYPEDEF_KEYS{typeDefIndex});
        tf = tf || strcmp(ancestorName, 'DynamicTable');
    end
end
