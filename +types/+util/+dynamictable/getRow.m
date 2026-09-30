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
% getRaggedRows - Get rows of a ragged column with one read per level.
%
% vectors lists the column's VectorData first and its VectorIndex objects
% after it, the outermost index last. Each level is read once, over the span
% of elements that the requested rows cover, and the rows are then sliced
% from those windows in memory. A column read from file therefore costs one
% read per level, whatever the number of rows and elements.
%
% selected is a cell array with one cell per requested row. For a doubly
% ragged column, each cell holds a cell array with one cell per element.

% Offsets are computed by subtraction, which saturates for unsigned integers.
rowIndices = double(rowIndices);

numLevels = numel(vectors);
windows = cell(1, numLevels);
% Element k of windows{iLevel} is element windowOffsets(iLevel) + k of that level.
windowOffsets = zeros(1, numLevels);

% Read the index levels from the outermost down. levelRows holds the rows
% requested from the current level.
levelRows = rowIndices;
hasEmptyDataRow = false;
for iLevel = numLevels:-1:2
    indexVector = vectors{iLevel};
    assert(isa(indexVector, 'types.hdmf_common.VectorIndex') || isa(indexVector, 'types.core.VectorIndex'), ...
        'NWB:DynamicTable:GetRow:InternalError', ...
        'Internal VectorIndex Stack is not using VectorIndex objects!');

    % Start one element early: the stop of the row before the first
    % requested row gives the first requested row's start.
    windowOffsets(iLevel) = max(min(levelRows) - 2, 0);
    windows{iLevel} = readIndexValues(indexVector, (windowOffsets(iLevel) + 1):max(levelRows));

    [starts, stops] = getElementRanges(windows{iLevel}, windowOffsets(iLevel), levelRows);
    isEmptyRow = starts > stops;
    if iLevel == 2
        hasEmptyDataRow = any(isEmptyRow);
    end
    if all(isEmptyRow)
        % No elements are requested from the levels below, so their
        % windows stay unread.
        levelRows = [];
        break
    end
    % Elements between the requested rows are read and discarded, which
    % keeps the next level to a single read.
    levelRows = min(starts(~isEmptyRow)):max(stops(~isEmptyRow));
end

dataVector = vectors{1};
if ~isempty(levelRows)
    windowOffsets(1) = levelRows(1) - 1;
    windows{1} = readRows(dataVector, levelRows);
end

emptyDataRow = [];
if hasEmptyDataRow
    % Read an empty selection from the column instead of slicing one from
    % the window, so an empty row has the type and shape of a direct read.
    emptyDataRow = orientRows(dataVector, readRows(dataVector, zeros(1, 0)));
end

[rank, rowAxis] = getRowDimension(dataVector);
ragged = struct( ...
    'Windows', {windows}, ...
    'WindowOffsets', windowOffsets, ...
    'DataVector', dataVector, ...
    'Rank', rank, ...
    'RowAxis', rowAxis, ...
    'EmptyDataRow', {emptyDataRow});
selected = sliceRaggedRows(ragged, numLevels, rowIndices);
end

function selected = sliceRaggedRows(ragged, level, rowIndices)
% sliceRaggedRows - Slice rows of an index level from the windows read by getRaggedRows.
[starts, stops] = getElementRanges(ragged.Windows{level}, ragged.WindowOffsets(level), rowIndices);
selected = cell(numel(rowIndices), 1);
for iRow = 1:numel(rowIndices)
    elementRows = starts(iRow):stops(iRow);
    if level > 2
        selected{iRow} = sliceRaggedRows(ragged, level - 1, elementRows);
    elseif isempty(elementRows)
        selected{iRow} = ragged.EmptyDataRow;
    else
        block = indexRows(ragged.Windows{1}, elementRows - ragged.WindowOffsets(1), ...
            ragged.Rank, ragged.RowAxis);
        selected{iRow} = orientRows(ragged.DataVector, block);
    end
end
end

function [starts, stops] = getElementRanges(indexWindow, windowOffset, rowIndices)
% getElementRanges - First and last element of index rows in the level below.
%
% Row r spans elements index(r-1)+1 through index(r) of the level below,
% where index(0) is 0. indexWindow(k) holds index(windowOffset + k).
stops = reshape(indexWindow(rowIndices - windowOffset), size(rowIndices));
starts = ones(size(rowIndices));
hasPreviousRow = rowIndices > 1;
starts(hasPreviousRow) = indexWindow(rowIndices(hasPreviousRow) - 1 - windowOffset) + 1;
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
% The same indexing reads a window from the column and slices rows from
% that window.
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
