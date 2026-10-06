function clear(dynamicTable)
%CLEAR Remove all rows and column data from a DynamicTable.
%
%   CLEAR(DYNAMICTABLE) removes every column object and the row ids of
%   DYNAMICTABLE. The `colnames` property is preserved, so rows can be
%   added to the same columns again.

    validateattributes(dynamicTable, ...
        {'types.hdmf_common.DynamicTable', 'types.core.DynamicTable'}, {'scalar'});

    % Entries are removed through the Set, which notifies the table so that
    % it drops the dynamic property it holds for each entry.
    dynamicTable.vectordata.clear();
    if isprop(dynamicTable, 'vectorindex') % Schema version <2.3.0
        dynamicTable.vectorindex.clear();
    end

    % Schema-defined columns are stored on their own properties.
    schemaColumnNames = dynamicTable.getSchemaDefinedColumns();
    for iColumn = 1:numel(schemaColumnNames)
        dynamicTable.(schemaColumnNames(iColumn)) = [];
    end

    dynamicTable.id = [];
    types.util.dynamictable.internal.initDynamicTableId(dynamicTable);
end
