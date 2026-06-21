function tf = isAlignedDynamicTableDescendant(name, namespace)
%ISALIGNEDDYNAMICTABLEDESCENDANT Check if a type inherits from AlignedDynamicTable.

    tf = false;

    if strcmp(name, 'AlignedDynamicTable')
        tf = true;
        return
    end

    ancestry = namespace.getRootBranch(name);
    for iAncestor = 1:length(ancestry)
        parentRaw = ancestry{iAncestor};
        typeDefIndex = isKey(parentRaw, namespace.TYPEDEF_KEYS);
        ancestorName = parentRaw(namespace.TYPEDEF_KEYS{typeDefIndex});
        tf = tf || strcmp(ancestorName, 'AlignedDynamicTable');
    end
end
