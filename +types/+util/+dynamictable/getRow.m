function row = getRow(DynamicTable, ind, varargin)
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
        indRanges = getIndexInd(DynamicTable, indexName, ind);
        colInd = [];
        if isa(VectorData.data, 'types.untyped.DataStub')...
                || isa(VectorData.data, 'types.untyped.DataPipe')
            totalHeight = VectorData.data.dims;
        else
            totalHeight = length(VectorData.data);
        end
        for j = 1:size(indRanges, 1)
            rangePair = indRanges(j, :);
            if isinf(rangePair(2))
                rangePair(2) = totalHeight;
            end
            colInd = [colInd rangePair(1):rangePair(2)]; 
        end
    end
    
    if isa(VectorData.data, 'types.untyped.DataStub')...
            || isa(VectorData.data, 'types.untyped.DataPipe')
        row{i} = VectorData.data.load(colInd);
    else
        row{i} = VectorData.data(colInd);
    end
end
end

function ind = getIndexInd(DynamicTable, indexName, matInd)
if isprop(DynamicTable, indexName)
    VectorIndex = DynamicTable.(indexName);
else
    VectorIndex = DynamicTable.vectorindex.get(indexName);
end
ind = [];
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

ind = [startInd stopInd];
end

function ind = getIndById(DynamicTable, id)
if isa(DynamicTable.id.data, 'types.untyped.DataStub')...
        || isa(DynamicTable.id.data, 'types.untyped.DataPipe')
    ids = DynamicTable.id.data.load();
else
    ids = DynamicTable.id.data;
end
ind = find(ismember(ids, id));
end