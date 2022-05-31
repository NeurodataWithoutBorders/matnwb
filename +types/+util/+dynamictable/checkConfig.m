function checkConfig(DynamicTable, varargin)
% CHECKCONFIG Given a DynamicTable object, this functions checks for proper
% DynamicTable configuration
%
%   checkConfig(DYNAMICTABLE) runs without error if the DynamicTable is
%   configured correctly
%
%   checkConfig(DYNAMICTABLE,IGNORELIST) performs checks on columns not in
%   IGNORELIST cell array
%
%
%  A properly configured DynamicTable should meet the following criteria:
%  1) The length of all columns in the dynamic table is the same.
%  2) All rows have a corresponding id. If none exist, this function creates them.
%  3) No index loops exist.
if nargin<2
    ignoreList = {};
else
    ignoreList = varargin{1};
end

if isempty(DynamicTable.colnames)
    assert(isempty(getDetectedColumnNames(DynamicTable)), ...
    'MatNWB:DynamicTable:CheckConfig:ColumnNamesMismatch', ...
    'All Vector Data/Index columns must have their name ordered in the `colnames` property.');
    return;
end

% remove null characters from column names
DynamicTable.colnames = cleanColumnNames(DynamicTable.colnames);

% do not check specified columns - useful for classes that build on DynamicTable class
columns = setdiff(DynamicTable.colnames, ignoreList);

columnHeights = zeros(length(columns), 1);
for iCol = 1:length(columns)
    columnName = retrieveHighestIndex(DynamicTable, columns{iCol});
    columnHeights(iCol) = getVectorHeight(getVector(DynamicTable, columnName));
end

tableHeight = unique(columnHeights);
if isempty(tableHeight)
    tableHeight = 0;
end
assert(isscalar(tableHeight), ...
    'MatNWB:DynamicTable:CheckConfig:InvalidShape', ...
    ['Invalid table detected: ' ...
    'column heights (vector lengths or number of matrix columns) must be the same.']);

if isempty(DynamicTable.id)
    idData = int64(1:tableHeight) .';
    if 8 == exist('types.core.ElementIdentifiers', 'class')
        DynamicTable.id = types.core.ElementIdentifiers('data', idData);
    else
        DynamicTable.id = types.hdmf_common.ElementIdentifiers('data', idData);
    end
    return;
end

assert(tableHeight == getVectorHeight(DynamicTable.id), ...
    'MatNWB:DynamicTable:CheckConfig:InvalidId', ...
    'Special column `id` of DynamicTable needs to match the detected height of %d. Found %d IDs.', ...
    tableHeight, length(DynamicTable.id.data));
end

function names = getDetectedColumnNames(DynamicTable)
% scan the entire dynamic table for columns that may or may not be
% registered.

names = {};
tableProps = properties(DynamicTable);
for iProp = 1:length(tableProps)
    propName = tableProps{iProp};
    propValue = DynamicTable.(propName);
    if ~isempty(propValue) ...
            && (isa(propValue, 'types.core.VectorData') || isa(propValue, 'types.hdmf_common.VectorData'))
        names{end+1} = propName;
    end
end

vectorNames = DynamicTable.vectordata.keys();
for iVector = 1:length(vectorNames)
    vectorName = vectorNames{iVector};
    Vector = DynamicTable.vectordata.get(vectorName);
    if isa(Vector, 'types.hdmf_common.VectorData') || isa(Vector, 'types.core.VectorData')
        if isa(Vector.data, 'types.untyped.DataStub')
            isDataEmpty = any(Vector.data.dims == 0);
        elseif isa(Vector.data, 'types.untyped.DataPipe')
            isDataEmpty = any(size(Vector.data) == 0);
        else
            isDataEmpty = isempty(Vector.data);
        end
        if ~isDataEmpty
            names{end+1} = vectorName;
        end
    end
end

end

function vecHeight = getVectorHeight(VectorData)
if isempty(VectorData)
    vecHeight = 0;
else
    vecHeight = getDataHeight(VectorData.data);
end
    function vecHeight = getDataHeight(data)
        if isempty(data)
            vecHeight = 0;
        elseif isa(data, 'types.untyped.DataPipe')
            vecHeight = data.offset;
        elseif isa(data, 'types.untyped.DataStub')
            vecHeight = data.dims(end);
        elseif isscalar(data) && isstruct(data) % compound type
            dataFieldNames = fieldnames(data);
            if isempty(dataFieldNames)
                vecHeight = 0;
            else
                vecHeight = getDataHeight(data.(dataFieldNames{1}));
            end
        elseif isscalar(data) || ~isvector(data)
            vecHeight = size(data, ndims(data));
        else
            vecHeight = size(data, find(1 < size(data)));
        end
    end
end

function Vector = getVector(DynamicTable, column)
if isprop(DynamicTable, column)
    Vector = DynamicTable.(column);
elseif isprop(DynamicTable, 'vectorindex') && isKey(DynamicTable.vectorindex, column)
    Vector = DynamicTable.vectorindex.get(column);
elseif isKey(DynamicTable.vectordata, column)
    Vector = DynamicTable.vectordata.get(column);
else
    Vector = [];
end
end

function highestName = retrieveHighestIndex(DynamicTable, column)
columnHistory = {};
highestName = column;
while true
    indexName = types.util.dynamictable.getIndex(DynamicTable, highestName);
    if isempty(indexName)
        return;
    end
    assert(~any(strcmp(columnHistory, indexName)), ...
        'MatNWB:DynamicTable:CheckConfig:InfiniteReferenceLoop', ...
        'Invalid Table shape detected: There is an infinite loop in your VectorIndex objects.');
    columnHistory{end+1} = indexName;
    highestName = indexName;
end
end

function colnames = cleanColumnNames(colnames)
%CLEANCOLUMNNAMES removes the null character from column names.
assert(iscellstr(colnames) || ischar(colnames), ...
    'MatNWB:DynamicTable:CheckConfig:InvalidColumnNames', ...
    'Column names must be a cell array of strings or a character array.');
isScalarChar = ischar(colnames);
if isScalarChar
   colnames = {colnames};
end

for iColumn = 1:length(colnames)
    column = colnames{iColumn};
    column = column(0 ~= double(column));
    colnames{iColumn} = column;
end

if isScalarChar
    colnames = colnames{1};
end
end