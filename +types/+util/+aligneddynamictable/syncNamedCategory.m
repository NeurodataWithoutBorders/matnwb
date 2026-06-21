function syncNamedCategory(alignedTable, categoryName)
%SYNCNAMEDCATEGORY Ensure a schema-defined category is registered.

    arguments
        alignedTable (1,1) types.hdmf_common.AlignedDynamicTable
        categoryName (1,:) char
    end

    if isempty(alignedTable.(categoryName))
        return
    end

    if strcmp(types.util.validationContext(), 'read')
        return
    end

    if isempty(alignedTable.categories)
        alignedTable.categories = {categoryName};
        return
    end

    alignedTable.categories = types.util.aligneddynamictable.validateCategories( ...
        alignedTable.categories);

    if ~any(strcmp(alignedTable.categories, categoryName))
        alignedTable.categories{end+1} = categoryName;
    end
end
