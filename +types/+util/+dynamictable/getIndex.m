function indexName = getIndex(DynamicTable, column)
%GETINDEX Given a dynamic table and its column name, get its VectorIndex column name
validateattributes(DynamicTable, {'types.hdmf_common.DynamicTable'}, {'scalar'});
validateattributes(column, {'char'}, {'scalartext'});
assert(any(strcmp(DynamicTable.colnames, column)),...
    'MatNWB:GetIndex:InvalidColumn',...
    'Column name not found `%s`', column);
indexName = '';
vecIndKeys = keys(DynamicTable.vectorindex);
for i = 1:length(vecIndKeys)
    vik = vecIndKeys{i};
    VecInd = DynamicTable.vectorindex.get(vik);
    if endsWith(VecInd.target.path, ['/' column])
        indexName = vik;
        return;
    end
end
end

