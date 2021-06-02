function indexName = getIndex(DynamicTable, column)
%GETINDEX Given a dynamic table and its column name, get its VectorIndex column name
validateattributes(DynamicTable, {'types.hdmf_common.DynamicTable'}, {'scalar'});
validateattributes(column, {'char'}, {'scalartext'});
indexName = '';
if strcmp(column, 'id')
    return;
end
assert(any(strcmp(DynamicTable.colnames, column)),...
    'NWB:GetIndex:InvalidColumn',...
    'Column name not found `%s`', column);

% after Schema version 2.3.0, VectorIndex objects subclass VectorData which
% meant that vectorindex and vectordata sets could be combined.
isLegacyDynamicTable = isprop(DynamicTable, 'vectorindex');
if isLegacyDynamicTable
    vecKeys = keys(DynamicTable.vectorindex);
else
    vecKeys = keys(DynamicTable.vectordata);
end
for i = 1:length(vecKeys)
    vk = vecKeys{i};
    if isLegacyDynamicTable
        vecData = DynamicTable.vectorindex.get(vk);
    else
        vecData = DynamicTable.vectordata.get(vk);
    end
    if ~isa(vecData, 'types.hdmf_common.VectorIndex')
        continue;
    end
    if isVecIndColumn(vecData, column)
        indexName = vk;
        return;
    end
end

% check if dynamic table object has extended properties which point to
% vector indices. These are specifically defined by the schema to be
% properties.
DynamicTableProps = properties(DynamicTable);
isPropVecInd = false(size(DynamicTableProps));
for i = 1:length(DynamicTableProps)
    isPropVecInd(i) = isa(DynamicTable.(DynamicTableProps{i}), 'types.hdmf_common.VectorIndex');
end

DynamicTableProps = DynamicTableProps(isPropVecInd);
for i = 1:length(DynamicTableProps)
    vk = DynamicTableProps{i};
    VecInd = DynamicTable.(vk);
    if isVecIndColumn(VecInd, column)
        indexName = vk;
        return;
    end
end
end

function tf = isVecIndColumn(VectorIndex, column)
tf = endsWith(VectorIndex.target.path, ['/' column]);
end

