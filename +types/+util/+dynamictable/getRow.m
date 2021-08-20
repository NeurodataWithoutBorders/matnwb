function subTable = getRow(DynamicTable, ind, varargin)
%GETROW get row for dynamictable
% Index is a scalar 0-based index of the expected row.
% optional keyword argument "columns" allows for only grabbing certain
%   columns instead of returning all columns.
% optional keyword `id` allows for row filtering by user-defined `id`
%   instead of row index.
% The returned value is a set of output arguments in the order of
% `colnames` or "columns" keyword argument if one exists.

validateattributes(DynamicTable,...
    {'types.core.DynamicTable', 'types.hdmf_common.DynamicTable'}, {'scalar'});
validateattributes(ind, {'numeric'}, {'positive', 'vector'});

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
    
    indexNames = {};
    columnName = cn;
    while true
        indexName = types.util.dynamictable.getIndex(DynamicTable, columnName);
        if isempty(indexName)
            break;
        end
        indexNames{end+1} = indexName;
        columnName = indexName;
    end

    if isprop(DynamicTable, cn)
        VectorData = DynamicTable.(cn);
    else
        VectorData = DynamicTable.vectordata.get(cn);
    end
    
    colInd = ind;
    selectionLengths = cell(size(indexNames));
    for iNames = length(indexNames):-1:1
        indMap = getIndexInd(DynamicTable, indexNames{iNames}, colInd);
        colInd = cell(1, length(ind)); % cell row because cell2mat must retain vector shape.
        for j = 1:length(ind)
            colInd{j} = indMap(ind(j));
        end
        selectionLengths{iNames} = cellfun('length', colInd);
        colInd = cell2mat(colInd);
    end
    
    if isa(VectorData.data, 'types.untyped.DataStub')...
            || isa(VectorData.data, 'types.untyped.DataPipe')
        row{i} = VectorData.data.load(colInd) .';
    else
        row{i} = VectorData.data(colInd);
    end
    
    for iLengths = 1:length(selectionLengths)
        row{i} = mat2cell(row{i}, selectionLengths{iLengths});
    end
end
subTable = table(row{:}, 'VariableNames', columns);
end

function indMap = getIndexInd(DynamicTable, indexName, matInd)
if isprop(DynamicTable, indexName)
    VectorIndex = DynamicTable.(indexName);
elseif isprop(DynamicTable, 'vectorindex') % Schema version < 2.3.0
    VectorIndex = DynamicTable.vectorindex.get(indexName);
else
    VectorIndex = DynamicTable.vectordata.get(indexName);
end

matInd = unique(matInd);
indexStartInd = matInd - 1;
startInd = zeros(size(matInd));
validIndexMask = indexStartInd > 0;
if isa(VectorIndex.data, 'types.untyped.DataStub')...
        || isa(VectorIndex.data, 'types.untyped.DataPipe')
    stopInd = VectorIndex.data.load(matInd);
    startInd(validIndexMask) = VectorIndex.data.load(indexStartInd(validIndexMask));
else
    stopInd = VectorIndex.data(matInd);
    startInd(validIndexMask) = VectorIndex.data(indexStartInd(validIndexMask));
end
startInd = startInd + 1; % Convert from 0-based indexing to 1-based indexing.
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
assert(all(idMatch), 'NWB:DynamicTable:GetRow:InvalidId',...
    'Invalid ids found. If you wish to use row indices directly, remove the `useId` flag.');
end