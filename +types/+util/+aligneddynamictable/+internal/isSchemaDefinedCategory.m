function tf = isSchemaDefinedCategory(alignedTable, categoryName)
%ISSCHEMADEFINEDCATEGORY Return true for generated schema category names.

    arguments
        alignedTable (1,1) types.hdmf_common.AlignedDynamicTable
        categoryName (1,1) string
    end

    schemaCategoryNames = alignedTable.getSchemaDefinedCategories();
    tf = any(schemaCategoryNames == categoryName);
end
