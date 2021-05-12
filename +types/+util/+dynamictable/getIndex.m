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

vecKeys = keys(DynamicTable.vectordata);
for i = 1:length(vecKeys)
    vk = vecKeys{i};
    vecData = DynamicTable.vectordata.get(vk);
    if ~isa(vecData, 'types.hdmf_common.VectorIndex')
        continue;
    end
    if isVecIndColumn(DynamicTable.vectordata.get(vk), column)
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

