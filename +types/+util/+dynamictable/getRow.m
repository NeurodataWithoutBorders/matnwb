function subTable = getRow(DynamicTable, ind, varargin)
%GETROW get row for dynamictable
% Index is a scalar 0-based index of the expected row.
% optional keyword argument "columns" allows for only grabbing certain
%   columns instead of returning all columns.
% optional keyword argument "categories" allows for only grabbing certain
%   categories from an AlignedDynamicTable.
% optional keyword `id` allows for row filtering by user-defined `id`
%   instead of row index.
% The returned value is a set of output arguments in the order of
% `colnames` or "columns" keyword argument if one exists.

validateattributes(DynamicTable,...
    {'types.core.DynamicTable', 'types.hdmf_common.DynamicTable'}, {'scalar'});
validateattributes(ind, {'numeric'}, {'integer', 'vector'});

p = inputParser;
addParameter(p, 'columns', DynamicTable.colnames, @(x)isempty(x)||iscellstr(x))
if isa(DynamicTable, 'matnwb.neurodata.AlignedDynamicTableBase')
    defaultCategories = DynamicTable.categories;
else
    defaultCategories = {};
end
addParameter(p, 'categories', defaultCategories, @(x)isempty(x)||iscellstr(x))
addParameter(p, 'useId', false, @(x)islogical(x));
parse(p, varargin{:});

columns = p.Results.columns;
categories = p.Results.categories;
row = cell(1, numel(columns) + numel(categories));

if p.Results.useId
    assert(~isempty(DynamicTable.id), ...
        'NWB:DynamicTable:GetRow:MissingId', ...
        'Cannot retrieve rows by `id` because the DynamicTable has no `id` column.');
    ind = getIndById(DynamicTable, ind);
else
    validateattributes(ind, {'numeric'}, {'positive', 'vector'});
    validateRowIndices(DynamicTable, ind);
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

    if ~istable(row{i})
        if iscolumn(row{i})
            % keep column vectors as is
        elseif isrow(row{i})
            row{i} = row{i} .'; % transpose row vectors
        elseif ndims(row{i}) >= 2 % i.e nd array where ndims >= 2
            % permute arrays to place last dimension first
            array_size = size(row{i});
            num_rows = numel(ind);

            is_row_dim = array_size == num_rows;
            if sum(is_row_dim) == 1
                if ~(is_row_dim(1) || is_row_dim(end))
                    throw( InvalidVectorDataShapeError(cn) )
                end
            elseif sum(is_row_dim) > 1
                if is_row_dim(1) && is_row_dim(end)
                    % Last dimension takes precedence
                    is_row_dim(1:end-1) = false;
                    warning('NWB:DynamicTable:VectorDataAmbiguousSize', ...
                        ['The length of the first and last dimensions of ', ...
                         'VectorData for column "%s" match the number of ', ...
                         'rows in the dynamic table. Data is rearranged based on ', ...
                         'the last dimension, assuming it corresponds with the table rows.'], cn) 
                elseif is_row_dim(1)
                    is_row_dim(2:end) = false;
                elseif is_row_dim(end)
                    is_row_dim(1:end-1) = false;
                else
                    throw( InvalidVectorDataShapeError(cn) )
                end
            end
            row{i} = permute( row{i}, [find(is_row_dim), find(~is_row_dim)]);
        end
    end

    % cell-wrap single multidimensional matrices to prevent invalid
    % MATLAB tables
    if isscalar(ind) && ~iscell(row{i}) && ~istable(row{i}) && ~isscalar(row{i})
        row{i} = row(i);
    end

    % convert compound data type scalar struct into an array of
    % structs.
    if isscalar(row{i}) && isstruct(row{i})
        structNames = fieldnames(row{i});
        scalarStruct = row{i};
        rowStruct = row{i}; % same as scalarStruct to maintain the field names.
        for iRow = 1:length(ind)
            for iField = 1:length(structNames)
                fieldName = structNames{iField};
                fieldData = scalarStruct.(fieldName);
                rowStruct(iRow).(fieldName) = fieldData(iRow);
            end
        end
        row{i} = rowStruct .';
    end
end
for iCategory = 1:numel(categories)
    categoryTable = DynamicTable.getCategory(categories{iCategory});
    row{numel(columns) + iCategory} = categoryTable.getRow(ind);
end

variableNames = [columns, categories];
if isempty(variableNames)
    subTable = table('Size', [numel(ind), 0], 'VariableTypes', {}, 'VariableNames', {});
else
    subTable = table(row{:}, 'VariableNames', variableNames);
end
end

function selected = select(DynamicTable, colIndStack, rowIndices)
% select - Get the requested rows of a column.
%
% colIndStack lists the column name first and the names of its VectorIndex
% columns after it, the outermost index last. A column without an index
% returns its rows as an array. A ragged column returns a cell array with
% one cell per row, nested once per index level.
vectors = cell(size(colIndStack));
for iVector = 1:numel(colIndStack)
    vectors{iVector} = getColumnVector(DynamicTable, colIndStack{iVector});
end

if isscalar(vectors)
    selected = orientRows(vectors{1}, readRows(vectors{1}, rowIndices));
else
    selected = getRaggedRows(vectors, rowIndices);
end
end

function vector = getColumnVector(DynamicTable, columnName)
% getColumnVector - Get the VectorData or VectorIndex object of a column by name.
if isprop(DynamicTable, columnName)
    vector = DynamicTable.(columnName);
elseif isprop(DynamicTable, 'vectorindex') && DynamicTable.vectorindex.isKey(columnName) % Schema version < 2.3.0
    vector = DynamicTable.vectorindex.get(columnName);
else
    vector = DynamicTable.vectordata.get(columnName);
end
end

function selected = getRaggedRows(vectors, rowIndices)
% getRaggedRows - Get rows of a ragged column, reading only the requested elements.
%
% vectors lists the column's VectorData first and its VectorIndex objects
% after it, the outermost index last. Each index level is read in one call,
% for exactly the index elements the requested rows need. The data is read
% for exactly the elements of the requested rows, in one call or in one call
% per contiguous run of elements (see readDataRows). The rows are then taken
% from those reads in memory.
%
% selected is a cell array with one cell per requested row. For a doubly
% ragged column, each cell holds a cell array with one cell per element.

% Row indices are shifted by subtraction, which saturates for unsigned integers.
rowIndices = double(reshape(rowIndices, 1, []));

numLevels = numel(vectors);
% rowStarts{iLevel} and rowStops{iLevel} give the element range, in the
% level below, of each row requested from level iLevel.
rowStarts = cell(1, numLevels);
rowStops = cell(1, numLevels);

% Read the index levels from the outermost down. levelRows lists the rows
% requested from the current level in output order, and after the loop the
% data elements requested from the column.
levelRows = rowIndices;
for iLevel = numLevels:-1:2
    indexVector = vectors{iLevel};
    assert(isa(indexVector, 'types.hdmf_common.VectorIndex') || isa(indexVector, 'types.core.VectorIndex'), ...
        'NWB:DynamicTable:GetRow:InternalError', ...
        'Internal VectorIndex Stack is not using VectorIndex objects!');

    [rowStarts{iLevel}, rowStops{iLevel}] = readElementRanges(indexVector, levelRows);
    levelRows = expandRanges(rowStarts{iLevel}, rowStops{iLevel});
end

rowValues = readDataRows(vectors{1}, rowStarts{2}, rowStops{2}, levelRows);

% Nest the rows of each level under their rows in the level above.
for iLevel = 3:numLevels
    rowLengths = max(rowStops{iLevel} - rowStarts{iLevel} + 1, 0);
    rowValues = mat2cell(rowValues, rowLengths(:), 1);
end
selected = rowValues;
end

function [starts, stops] = readElementRanges(indexVector, rowIndices)
% readElementRanges - Element range of VectorIndex rows in the level below.
%
% Row r spans elements index(r-1)+1 through index(r) of the level below,
% where index(0) is 0. The index values of all rows are read in one call.
starts = ones(size(rowIndices));
stops = zeros(size(rowIndices));
if isempty(rowIndices)
    return
end

indexElements = unique([rowIndices, rowIndices - 1]);
indexElements(indexElements == 0) = [];
indexValues = readIndexValues(indexVector, indexElements);

[~, stopPositions] = ismember(rowIndices, indexElements);
stops = reshape(indexValues(stopPositions), size(rowIndices));
hasPreviousRow = rowIndices > 1;
[~, previousPositions] = ismember(rowIndices(hasPreviousRow) - 1, indexElements);
starts(hasPreviousRow) = indexValues(previousPositions) + 1;
end

function elements = expandRanges(starts, stops)
% expandRanges - Concatenate the ranges starts(i):stops(i) into one row vector.
isNonEmpty = starts <= stops;
starts = starts(isNonEmpty);
stops = stops(isNonEmpty);
if isempty(starts)
    elements = zeros(1, 0);
    return
end

% Consecutive elements differ by 1 within a range. The first element of a
% range differs from the last element of the range before it by the gap.
steps = ones(1, sum(stops - starts + 1));
rangeFirst = cumsum([1, stops(1:end-1) - starts(1:end-1) + 1]);
steps(rangeFirst) = [starts(1), starts(2:end) - stops(1:end-1)];
elements = cumsum(steps);
end

function rowValues = readDataRows(dataVector, starts, stops, elements)
% readDataRows - Read the data of ragged rows, one cell per row.
%
% Row i holds data elements starts(i) through stops(i), and elements lists
% the elements of all rows. A column indexed with one subscript reads any
% set of elements in one call. With more subscripts, a selection with gaps
% becomes one hyperslab per contiguous run, and building it takes time that
% grows faster than linearly with the number of runs, so each run is read
% in a call of its own.
[rank, rowAxis] = getRowDimension(dataVector);
elements = unique(elements);
numElements = numel(elements);
if numElements == 0
    [runFirst, runLast] = deal(zeros(1, 0));
elseif rank == 1
    [runFirst, runLast] = deal(1, numElements);
else
    runFirst = find([true, diff(elements) > 1]);
    runLast = [runFirst(2:end) - 1, numElements];
end

blocks = cell(size(runFirst));
for iRun = 1:numel(runFirst)
    blocks{iRun} = readRows(dataVector, elements(runFirst(iRun):runLast(iRun)));
end
% runOfPosition(k) is the run that holds elements(k).
runOfPosition = zeros(1, numElements);
runOfPosition(runFirst) = 1;
runOfPosition = cumsum(runOfPosition);

isEmptyRow = starts > stops;
emptyRow = [];
if any(isEmptyRow)
    % Read an empty selection from the column instead of taking one from a
    % block, so an empty row has the type and shape of a direct read.
    emptyRow = orientRows(dataVector, readRows(dataVector, zeros(1, 0)));
end

% The elements of a row are consecutive in elements and lie in one run.
[~, startPositions] = ismember(starts, elements);
rowValues = cell(numel(starts), 1);
for iRow = 1:numel(starts)
    if isEmptyRow(iRow)
        rowValues{iRow} = emptyRow;
    else
        iRun = runOfPosition(startPositions(iRow));
        blockRows = startPositions(iRow) - runFirst(iRun) + 1 + (0:(stops(iRow) - starts(iRow)));
        block = indexRows(blocks{iRun}, blockRows, rank, rowAxis);
        rowValues{iRow} = orientRows(dataVector, block);
    end
end
end

function values = readIndexValues(indexVector, elementIndices)
% readIndexValues - Read elements of a VectorIndex as a double column vector.
if isa(indexVector.data, 'types.untyped.DataStub') || isa(indexVector.data, 'types.untyped.DataPipe')
    values = indexVector.data.load(elementIndices);
else
    values = indexVector.data(elementIndices);
end
values = double(values(:));
end

function block = readRows(vector, rowIndices)
% readRows - Read rows of a column, leaving the rows along the column's row axis.
[rank, rowAxis] = getRowDimension(vector);
block = indexRows(vector.data, rowIndices, rank, rowAxis);
end

function selected = orientRows(vector, block)
% orientRows - Put the row axis first for a DataPipe column.
%
% shift dimensions of non-row vectors. otherwise will result in
% invalid MATLAB table with uneven column height
if isa(vector.data, 'types.untyped.DataPipe')
    selected = permute(block, circshift(1:ndims(block), -(vector.data.axis-1)));
else
    selected = block;
end
end

function [rank, rowAxis] = getRowDimension(vector)
% getRowDimension - Number of subscripts used to index a column, and the one that selects rows.
data = vector.data;
if isa(data, 'types.untyped.DataStub') || isa(data, 'types.untyped.DataPipe')
    if isa(data, 'types.untyped.DataStub')
        refProp = data.dims;
    else
        refProp = data.internal.maxSize;
    end
    if length(refProp) == 2 && refProp(2) == 1
        % catch row vector
        rank = 1;
    else
        rank = length(refProp);
    end
else
    if iscolumn(data)
        %catch row vector
        rank = 1;
    elseif istable(data)
        rank = 1;
    else
        rank = ndims(data);
    end
end

if isa(data, 'types.untyped.DataPipe')
    rowAxis = data.axis;
else
    rowAxis = rank;
end
end

function selected = indexRows(data, rowIndices, rank, rowAxis)
% indexRows - Index rows of in-memory or file-backed column data.
%
% The same indexing reads rows from the column and takes rows from a block
% already read from it.
selectInd = repmat({':'}, 1, rank);
selectInd{rowAxis} = rowIndices;

if (isstruct(data) && isscalar(data)) || istable(data)
    if istable(data)
        selected = table();
        fields = data.Properties.VariableNames;
    else
        selected = struct();
        fields = fieldnames(data);
    end

    for i = 1:length(fields)
        fieldName = fields{i};
        columnData = data.(fieldName);
        selected.(fieldName) = columnData(selectInd{:});
    end
else
    selected = data(selectInd{:});
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

function validateRowIndices(dynamicTable, rowIndices)
    tableHeight = types.util.dynamictable.internal.getTableHeight(dynamicTable);

    assert(all(rowIndices <= tableHeight), ...
        'NWB:DynamicTable:GetRow:RowOutOfBounds', ...
        'Requested row index (%s) exceeds the DynamicTable height of %d.', ...
        strjoin(compose('%d', rowIndices(rowIndices > tableHeight) ), ', '), tableHeight);
end

function ME = InvalidVectorDataShapeError(column_name)
    ME = MException('NWB:DynamicTable:InvalidVectorDataShape', ...
            sprintf( ['Array data for column "%s" has a shape which do ', ...
                      'not match the number of rows in the dynamic table.'], column_name ));
end
