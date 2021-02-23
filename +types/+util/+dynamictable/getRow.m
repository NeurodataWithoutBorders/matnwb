function subTable = getRow(DynamicTable, ind, varargin)
%GETROW get row for dynamictable
% Index is a scalar 0-based index of the expected row.
% optional keyword argument "columns" allows for only grabbing certain
%   columns instead of returning all columns.
% optional keyword `id` allows for row filtering by user-defined `id`
%   instead of row index.
% The returned value is a set of output arguments in the order of
% `colnames` or "columns" keyword argument if one exists.

validateattributes(DynamicTable, {'types.hdmf_common.DynamicTable'}, {'scalar'});
validateattributes(ind, {'numeric'}, {'positive'});

p = inputParser;
addParameter(p, 'columns', DynamicTable.colnames, @(x)iscellstr(x));
addParameter(p, 'useId', false, @(x)islogical(x));
parse(p, varargin{:});

columns = p.Results.columns;
row = cell(1, length(columns));

if isempty(DynamicTable.id)
    DynamicTable.id = types.hdmf_common.ElementIdentifiers();
    return;
end

if p.Results.useId
    ind = getIndById(DynamicTable, ind);
end

for i = 1:length(columns)
    cn = columns{i};
    indexName = types.util.dynamictable.getIndex(DynamicTable, cn);

    if isprop(DynamicTable, cn)
        VectorData = DynamicTable.(cn);
    else
        VectorData = DynamicTable.vectordata.get(cn);
    end
    
    if isempty(indexName)
        colInd = ind;
    else
        indMap = getIndexInd(DynamicTable, indexName, ind);
        colInd = cell(size(ind));
        for j = 1:length(ind)
            colInd{j} = indMap(ind(j));
        end
        colInd = cell2mat(colInd);
    end
    
    if isa(VectorData.data, 'types.untyped.DataStub')...
            || isa(VectorData.data, 'types.untyped.DataPipe')
        row{i} = VectorData.data.load(colInd) .';
    else
        row{i} = VectorData.data(colInd);
    end
end
subTable = table(row{:}, 'VariableNames', columns);
end

function indMap = getIndexInd(DynamicTable, indexName, matInd)
if isprop(DynamicTable, indexName)
    VectorIndex = DynamicTable.(indexName);
else
    VectorIndex = DynamicTable.vectorindex.get(indexName);
end

matInd = unique(matInd);
matStartInd = matInd - 1;
startInd = ones(size(matInd));
if isa(VectorIndex.data, 'types.untyped.DataStub')...
        || isa(VectorIndex.data, 'types.untyped.DataPipe')
    stopInd = VectorIndex.data.load(matInd);
    startInd(matStartInd > 0) = VectorIndex.data.load(matStartInd(matStartInd > 0));
else
    stopInd = VectorIndex.data(matInd);
    startInd(matStartInd > 0) = VectorIndex.data(matStartInd(matStartInd > 0));
end
indMap = containers.Map('KeyType', 'uint64', 'ValueType', 'any');
for i = 1:length(startInd)
    indMap(matInd(i)) = startInd(i):stopInd(i);
end
end

function ind = getIndById(DynamicTable, id)
if isa(DynamicTable.id.data, 'types.untyped.DataStub')...
        || isa(DynamicTable.id.data, 'types.untyped.DataPipe')
    ids = DynamicTable.id.data.load();
else
    ids = DynamicTable.id.data;
end
[idMatch, ind] = ismember(id, ids);
assert(all(idMatch), 'MatNWB:DynamicTable:GetRow:InvalidId',...
    'Invalid ids found. If you wish to use row indices directly, remove the `useId` flag.');
end