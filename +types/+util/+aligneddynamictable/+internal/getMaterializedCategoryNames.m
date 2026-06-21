function categoryNames = getMaterializedCategoryNames(alignedTable)
%GETMATERIALIZEDCATEGORYNAMES Return non-empty category table names.

    arguments
        alignedTable (1,1) types.hdmf_common.AlignedDynamicTable
    end

    categoryNames = string.empty(1, 0);
    schemaCategoryNames = alignedTable.getSchemaDefinedCategories();

    for iCategory = 1:numel(schemaCategoryNames)
        categoryName = schemaCategoryNames(iCategory);
        if isprop(alignedTable, categoryName) && ~isempty(alignedTable.(categoryName))
            categoryNames(end+1) = categoryName; %#ok<AGROW>
        end
    end

    if ~isempty(alignedTable.dynamictable)
        customCategoryNames = string(alignedTable.dynamictable.keys());
        categoryNames = [categoryNames, customCategoryNames];
    end

    categoryNames = cellstr(unique(categoryNames, 'stable'));
end
