function columnDescriptions = getColumnDescriptions(dynamicTable, columnNames)
%getColumnDescriptions - Return descriptions for DynamicTable columns.

    arguments
        dynamicTable (1,1) {matnwb.common.validation.mustBeDynamicTable}
        columnNames (1,:)
    end

    columnDescriptions = cell(1, numel(columnNames));
    for iColumn = 1:numel(columnNames)
        columnName = columnNames{iColumn};
        if isprop(dynamicTable, columnName)
            column = dynamicTable.(columnName);
        elseif isprop(dynamicTable, 'vectorindex') && ...
                dynamicTable.vectorindex.isKey(columnName)
            column = dynamicTable.vectorindex.get(columnName);
        else
            column = dynamicTable.vectordata.get(columnName);
        end
        columnDescriptions{iColumn} = column.description;
    end
end
