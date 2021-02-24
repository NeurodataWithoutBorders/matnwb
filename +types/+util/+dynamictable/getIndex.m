function indexName = getIndex(DynamicTable, column)
%GETINDEX Given a dynamic table and its column name, get its VectorIndex column name
validateattributes(DynamicTable, {'types.hdmf_common.DynamicTable'}, {'scalar'});
validateattributes(column, {'char'}, {'scalartext'});
indexName = '';
if strcmp(column, 'id')
    return;
end
assert(any(strcmp(DynamicTable.colnames, column)),...
    'MatNWB:GetIndex:InvalidColumn',...
    'Column name not found `%s`', column);

vecIndKeys = keys(DynamicTable.vectorindex);
for i = 1:length(vecIndKeys)
    vik = vecIndKeys{i};
    if isVecIndColumn(DynamicTable.vectorindex.get(vik), column)
        indexName = vik;
        return;
    end
end

DynamicTableProps = properties(DynamicTable);
isPropVecInd = false(size(DynamicTableProps));
for i = 1:length(DynamicTableProps)
    isPropVecInd(i) = isa(DynamicTable.(DynamicTableProps{i}), 'types.hdmf_common.VectorIndex');
end

DynamicTableProps = DynamicTableProps(isPropVecInd);
for i = 1:length(DynamicTableProps)
    vik = DynamicTableProps{i};
    VecInd = DynamicTable.(vik);
    if isVecIndColumn(VecInd, column)
        indexName = vik;
        return;
    end
end
end

function tf = isVecIndColumn(VectorIndex, column)
tf = endsWith(VectorIndex.target.path, ['/' column]);
end

