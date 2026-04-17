function syncNamedColumn(DynamicTable, columnName)
%SYNCNAMEDCOLUMN Ensure a schema-defined column is registered in colnames.

    arguments
        DynamicTable
        columnName (1,:) char
    end

    if isempty(DynamicTable.(columnName))
        return
    end

    if isempty(DynamicTable.colnames)
        DynamicTable.colnames = {columnName};
        return
    end

    DynamicTable.colnames = types.util.dynamictable.validateColnames(DynamicTable.colnames);
    if ~any(strcmp(DynamicTable.colnames, columnName))
        DynamicTable.colnames{end+1} = columnName;
    end
end
