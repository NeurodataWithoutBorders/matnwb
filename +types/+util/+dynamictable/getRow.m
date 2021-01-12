function varargout = getRow(DynamicTable, id, varargin)
%GETROW get row for dynamictable
% Index is a scalar 0-based index of the expected row.
% optional keyword argument "columns" allows for only grabbing certain
% columns instead of returning all columns.
% The returned value is a set of output arguments in the order of
% `colnames` or "columns" keyword argument if one exists.

validateattributes(DynamicTable, {'types.hdmf_common.DynamicTable'}, {'scalar'});

if isempty(DynamicTable.id)
    DynamicTable.id = types.hdmf_common.ElementIdentifiers();
end

if isa(DynamicTable.id.data, 'types.untyped.DataStub')...
        || isa(DynamicTable.id.data, 'types.untyped.DataPipe')
    stubSize = size(DynamicTable.id.data);
    maxId = stubSize(1) - 1;
else
    maxId = DynamicTable.id.data(end);
end
assert(~isempty(maxId) && maxId >= 0, 'MatNWB:getRow:EmptyTable', 'Dynamic Table is Empty');
validateattributes(id, {'numeric'}, {'scalar', 'nonnegative', '<=', maxId});

p = inputParser;
addParameter(p, 'columns', DynamicTable.colnames, @(x)iscellstr(x));
parse(p, varargin{:});

columns = p.Results.columns;
varargout = cell(1, length(columns));
for i = 1:length(columns)
    cn = columns{i};
    indexName = types.util.dynamictable.getIndex(DynamicTable, cn);
    
    matInd = id + 1;
    VectorData = DynamicTable.vectordata.get(cn);
    if isempty(indexName)
        offset = matInd;
        nextIndex = offset + 1;
    else
        [offset, nextIndex] = getIndexRange(DynamicTable, indexName, matInd);
    end
    
    if isinf(nextIndex)
        nextIndex = size(VectorData.data, 1) + 1;
    end
    
    dataRange = offset:(nextIndex - 1);
    if isa(VectorData.data, 'types.untyped.DataStub')...
            || isa(VectorData.data, 'types.untyped.DataPipe')
        varargout{i} = VectorData.data.load(dataRange);
    else
        varargout{i} = VectorData.data(dataRange);
    end
end
end

function [offset, nextIndex] = getIndexRange(DynamicTable, indexName, matInd)
VectorIndex = DynamicTable.vectorindex.get(indexName);
if isa(VectorIndex.data, 'types.untyped.DataStub')...
        || isa(VectorIndex.data, 'types.untyped.DataPipe')
    totalHeight = size(VectorIndex.data);
    totalHeight = totalHeight(1);
    offset = VectorIndex.data.load(matInd) + 1;
    if matInd == totalHeight
        nextIndex = Inf;
    else
        nextIndex = VectorIndex.data.load(matInd + 1);
    end
else
    offset = VectorIndex.data(matInd) + 1;
    if matInd == length(VectorIndex.data)
        nextIndex = Inf;
    else
        nextIndex = VectorIndex.data(matInd + 1);
    end
end
end