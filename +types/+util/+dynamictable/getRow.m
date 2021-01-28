function varargout = getRow(DynamicTable, ind, varargin)
%GETROW get row for dynamictable
% Index is a scalar 0-based index of the expected row.
% optional keyword argument "columns" allows for only grabbing certain
%   columns instead of returning all columns.
% optional keyword `id` allows for row filtering by user-defined `id`
%   instead of row index.
% The returned value is a set of output arguments in the order of
% `colnames` or "columns" keyword argument if one exists.

validateattributes(DynamicTable, {'types.hdmf_common.DynamicTable'}, {'scalar'});

if isempty(DynamicTable.id)
    DynamicTable.id = types.hdmf_common.ElementIdentifiers();
end

assert(~isempty(maxId) && maxId >= 0, 'MatNWB:getRow:EmptyTable', 'Dynamic Table is Empty');
validateattributes(ind, {'numeric'}, {'scalar', 'positive'});

p = inputParser;
addParameter(p, 'columns', DynamicTable.colnames, @(x)iscellstr(x));
addParameter(p, 'useId', false, @(x)islogical(x));
parse(p, varargin{:});

if p.Results.useId
    ind = getIndById(DynamicTable, ind);
end

columns = p.Results.columns;
varargout = cell(1, length(columns));
for i = 1:length(columns)
    cn = columns{i};
    indexName = types.util.dynamictable.getIndex(DynamicTable, cn);
    if ~isempty(indexName)
        ind = getIndexInd(DynamicTable, indexName, ind);
    end
    
    VectorData = DynamicTable.vectordata.get(cn);
    if isa(VectorData.data, 'types.untyped.DataStub')...
            || isa(VectorData.data, 'types.untyped.DataPipe')
        varargout{i} = VectorData.data.load(ind);
    else
        varargout{i} = VectorData.data(ind);
    end
end
end

function ind = getIndexInd(DynamicTable, indexName, matInd)
VectorIndex = DynamicTable.vectorindex.get(indexName);
ind = [];
matInd = unique(matInd);
if isa(VectorIndex.data, 'types.untyped.DataStub')...
        || isa(VectorIndex.data, 'types.untyped.DataPipe')
    totalHeight = size(VectorIndex.data);
    totalHeight = totalHeight(1);
    startInd = VectorIndex.data.load(matInd) + 1;
    indexStopInd = matInd + 1;
    indexStopInd(indexStopInd > totalHeight) = [];
    stopInd = VectorIndex.data.load(indexStopInd);
else
    startInd = VectorIndex.data(matInd) + 1;
    indexStopInd = matInd + 1;
    indexStopInd(indexStopInd > length(VectorIndex.data)) = [];
    stopInd = VectorIndex.data(indexStopInd);
end

if length(stopInd) < length(startInd)
    stopInd(end+1) = Inf;
end
for i = 1:length(startInd)
    ind = [ind startInd(i):stopInd(i)];
end
end

function ind = getIndById(DynamicTable, id)
if isa(DynamicTable.id.data, 'types.untyped.DataStub')...
        || isa(DynamicTable.id.data, 'types.untyped.DataPipe')
    ids = DynamicTable.id.data.load();
else
    ids = DynamicTable.id.data;
end
ind = id == ids;
end