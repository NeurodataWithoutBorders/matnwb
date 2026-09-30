function clear(DynamicTable)
%CLEAR Remove all rows and column data from a DynamicTable.
%
%   CLEAR(DYNAMICTABLE) removes every column object and the row ids of
%   DYNAMICTABLE. The `colnames` property is preserved, so rows can be
%   added to the same columns again.

    validateattributes(DynamicTable, ...
        {'types.hdmf_common.DynamicTable', 'types.core.DynamicTable'}, {'scalar'});

    % Entries are removed through the Set, which notifies the table so that
    % it drops the dynamic property it holds for each entry.
    DynamicTable.vectordata.clear();
    if isprop(DynamicTable, 'vectorindex') % Schema version <2.3.0
        DynamicTable.vectorindex.clear();
    end

    % Schema-defined columns are stored on their own properties.
    schemaColumnNames = DynamicTable.getSchemaDefinedColumns();
    for iColumn = 1:numel(schemaColumnNames)
        DynamicTable.(schemaColumnNames(iColumn)) = [];
    end

    DynamicTable.id = [];
    types.util.dynamictable.internal.initDynamicTableId(DynamicTable);
end
