function clear(DynamicTable)
    %CLEAR Given a valid DynamicTable object, clears all rows and type
    %   information in the table.

    types.util.dynamictable.clear(DynamicTable);

    assert(isa(DynamicTable, 'types.hdmf_common.AlignedDynamicTable') ...
        , 'MatNWB:DynamicTable:InvalidAlignedTableType' ...
        , 'alignedtable.clear() can only be called with a valid Aligned Table.');
    DynamicTable.categories = {};
    DynamicTable.dynamictable.clear();
end
