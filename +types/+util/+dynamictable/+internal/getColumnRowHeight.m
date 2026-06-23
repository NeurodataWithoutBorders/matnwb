function [columnRowHeight, resolvedColumnName, hasEstablishedHeight] = getColumnRowHeight(dynamicTable, columnName)
% getColumnRowHeight - Return the row height for a DynamicTable column.
%
% For ragged columns, this follows VectorIndex links to the outermost index
% column, whose height corresponds to the number of table rows.

    arguments
        dynamicTable
        columnName {mustBeTextScalar}
    end

    columnName = char(columnName);
    resolvedColumnName = types.util.dynamictable.internal.getOutermostIndexColumnName( ...
        dynamicTable, columnName);
    vector = getVector(dynamicTable, resolvedColumnName);
    [columnRowHeight, hasEstablishedHeight] = ...
        types.util.dynamictable.internal.getColumnHeight(vector);
    hasEstablishedHeight = hasEstablishedHeight || ~isempty(vector);
end

function vector = getVector(dynamicTable, columnName)
    if isprop(dynamicTable, columnName)
        vector = dynamicTable.(columnName);
    elseif isprop(dynamicTable, 'vectorindex') && dynamicTable.vectorindex.isKey(columnName)
        vector = dynamicTable.vectorindex.get(columnName);
    elseif dynamicTable.vectordata.isKey(columnName)
        vector = dynamicTable.vectordata.get(columnName);
    else
        vector = [];
    end
end
