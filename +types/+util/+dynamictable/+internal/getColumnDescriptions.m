function columnDescriptions = getColumnDescriptions(dynamicTable, columnNames)
%getColumnDescriptions - Return descriptions for DynamicTable columns.
%
%   columnDescriptions is a row cell array of character vectors, the form
%   the VariableDescriptions property of a MATLAB table takes. A description
%   held as a string scalar is converted.

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
        columnDescriptions{iColumn} = char(column.description);
    end
end
