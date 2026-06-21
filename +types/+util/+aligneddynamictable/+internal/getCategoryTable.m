function categoryTable = getCategoryTable(alignedTable, categoryName)
%GETCATEGORYTABLE Return a schema-defined or custom category table.

    arguments
        alignedTable (1,1) types.hdmf_common.AlignedDynamicTable
        categoryName (1,1) string
    end

    if types.util.aligneddynamictable.internal.isSchemaDefinedCategory( ...
            alignedTable, categoryName)
        categoryTable = alignedTable.(categoryName);
    else
        categoryTable = alignedTable.dynamictable.get(categoryName);
    end
end
