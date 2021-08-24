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
    
    indexNames = {cn};
    while true
        name = types.util.dynamictable.getIndex(DynamicTable, indexNames{end});
        if isempty(name)
            break;
        end
        indexNames{end+1} = name;
    end
    
    row{i} = select(DynamicTable, indexNames, ind);
end
subTable = table(row{:}, 'VariableNames', columns);
end

function selected = select(DynamicTable, colIndStack, matInd)
% recursive function which consumes the colIndStack and produces a nested
% cell array.
column = colIndStack{end};
if isprop(DynamicTable, column)
    Vector = DynamicTable.(column);
elseif isprop(DynamicTable, 'vectorindex') && DynamicTable.vectorindex.isKey(column) % Schema version < 2.3.0
    Vector = DynamicTable.vectorindex.get(column);
else
    Vector = DynamicTable.vectordata.get(column);
end

if isa(Vector, 'types.hdmf_common.VectorIndex') || isa(Vector, 'types.core.VectorIndex')
    indKeys = unique(matInd);
    indexStartInd = indKeys - 1; % get previous index.
    startInd = zeros(size(matInd), 'uint64'); % 0-index case.
    validIndexMask = indexStartInd > 0;
    if isa(Vector.data, 'types.untyped.DataStub') || isa(Vector.data, 'types.untyped.DataPipe')
        stopInd = uint64(Vector.data.load(indKeys));
        startInd(validIndexMask) = Vector.data.load(indexStartInd(validIndexMask));
    else
        stopInd = uint64(Vector.data(indKeys));
        startInd(validIndexMask) = Vector.data(indexStartInd(validIndexMask));
    end
    startInd = startInd + 1; % 0-based to 1-based inclusive range.
    selected = cell(length(matInd), 1);
    for iSelection = 1:length(matInd)
        keyInd = indKeys == matInd(iSelection);
        selected{iSelection} = select(...
            DynamicTable,...
            colIndStack(1:(end-1)),...
            startInd(keyInd):stopInd(keyInd));
    end
else
    if isa(Vector.data, 'types.untyped.DataPipe')
        selected = Vector.data.load(matInd);
    else
        selected = Vector.data(matInd);
    end
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