function subTable = getRow(DynamicTable, rowIndices, options)
%GETROW Get rows of a DynamicTable as a MATLAB table.
%
% rowIndices is a vector of 1-based row indices. Columns stored in a file
% are read for the requested rows only. Looking rows up by id reads the
% whole id column.
%
% Name-value arguments:
%   "columns"    - Names of the columns to return. Defaults to every column,
%                  in the order of the table's colnames property.
%   "categories" - Names of the categories of an AlignedDynamicTable to
%                  return, each as a nested table. Defaults to every category.
%   "useId"      - When true, rowIndices lists values of the table's id
%                  column instead of row indices.
%
% subTable has one row per requested row, one variable per requested column
% and then one variable per requested category.

arguments
    DynamicTable (1,1) {matnwb.common.validation.mustBeDynamicTable}
    rowIndices (1,:) {mustBeNumeric, mustBeInteger}
    options.columns {mustBeCellstrOrEmpty} = DynamicTable.colnames
    options.categories {mustBeCellstrOrEmpty} = getDefaultCategories(DynamicTable)
    options.useId (1,1) logical = false
end

% Names read from a file are column cell arrays.
columns = reshape(options.columns, 1, []);
categories = reshape(options.categories, 1, []);
columnData = cell(1, numel(columns) + numel(categories));

if options.useId
    assert(~isempty(DynamicTable.id), ...
        'NWB:DynamicTable:GetRow:MissingId', ...
        'Cannot retrieve rows by `id` because the DynamicTable has no `id` column.');
    rowIndices = getRowIndicesById(DynamicTable, rowIndices);
else
    validateattributes(rowIndices, {'numeric'}, {'positive', 'vector'});
    validateRowIndices(DynamicTable, rowIndices);
end

for iColumn = 1:length(columns)
    columnName = columns{iColumn};

    % Collect the column and the chain of VectorIndex columns above it, the
    % column first and the outermost index last.
    vectorChainNames = {columnName};
    while true
        name = types.util.dynamictable.getIndex(DynamicTable, vectorChainNames{end});
        if isempty(name)
            break;
        end
        vectorChainNames{end+1} = name;
    end

    columnData{iColumn} = getColumnRows(DynamicTable, vectorChainNames, rowIndices);

    if ~istable(columnData{iColumn})
        if iscolumn(columnData{iColumn})
            % keep column vectors as is
        elseif isrow(columnData{iColumn})
            columnData{iColumn} = columnData{iColumn} .'; % transpose row vectors
        elseif ndims(columnData{iColumn}) >= 2
            % Move the dimension that spans the table rows first. The rows
            % must lie along the first or the last dimension.
            arraySize = size(columnData{iColumn});
            numRows = numel(rowIndices);

            isRowDimension = arraySize == numRows;
            if sum(isRowDimension) == 1
                if ~(isRowDimension(1) || isRowDimension(end))
                    throw( createInvalidShapeError(columnName) )
                end
            elseif sum(isRowDimension) > 1
                if isRowDimension(1) && isRowDimension(end)
                    % Last dimension takes precedence
                    isRowDimension(1:end-1) = false;
                    warning('NWB:DynamicTable:VectorDataAmbiguousSize', ...
                        ['The length of the first and last dimensions of ', ...
                         'VectorData for column "%s" match the number of ', ...
                         'rows in the dynamic table. Data is rearranged based on ', ...
                         'the last dimension, assuming it corresponds with the table rows.'], columnName) 
                elseif isRowDimension(1)
                    isRowDimension(2:end) = false;
                elseif isRowDimension(end)
                    isRowDimension(1:end-1) = false;
                else
                    throw( createInvalidShapeError(columnName) )
                end
            end
            columnData{iColumn} = permute( columnData{iColumn}, [find(isRowDimension), find(~isRowDimension)]);
        end
    end

    % A single row holding an array is wrapped in a cell, or table() would
    % spread the array over several rows.
    if isscalar(rowIndices) && ~iscell(columnData{iColumn}) ...
            && ~istable(columnData{iColumn}) && ~isscalar(columnData{iColumn})
        columnData{iColumn} = columnData(iColumn);
    end

    % A compound column in memory is a scalar struct with one array per
    % member. Split it into a struct array with one element per row.
    if isscalar(columnData{iColumn}) && isstruct(columnData{iColumn})
        compoundMemberNames = fieldnames(columnData{iColumn});
        scalarStruct = columnData{iColumn};
        rowStruct = columnData{iColumn}; % same as scalarStruct to maintain the field names.
        for iRow = 1:length(rowIndices)
            for iField = 1:length(compoundMemberNames)
                fieldName = compoundMemberNames{iField};
                fieldData = scalarStruct.(fieldName);
                rowStruct(iRow).(fieldName) = fieldData(iRow);
            end
        end
        columnData{iColumn} = rowStruct .';
    end
end
for iCategory = 1:numel(categories)
    categoryTable = DynamicTable.getCategory(categories{iCategory});
    columnData{numel(columns) + iCategory} = categoryTable.getRow(rowIndices);
end

variableNames = [columns, categories];
if isempty(variableNames)
    subTable = table('Size', [numel(rowIndices), 0], 'VariableTypes', {}, 'VariableNames', {});
else
    subTable = table(columnData{:}, 'VariableNames', variableNames);
end
end

function categories = getDefaultCategories(DynamicTable)
% getDefaultCategories - Every category of an AlignedDynamicTable, none for other tables.
if isa(DynamicTable, 'matnwb.neurodata.AlignedDynamicTableBase')
    categories = DynamicTable.categories;
else
    categories = {};
end
end

function mustBeCellstrOrEmpty(value)
% mustBeCellstrOrEmpty - Validate that value is empty or a cell array of character vectors.
if ~(isempty(value) || iscellstr(value))
    error('NWB:DynamicTable:GetRow:InvalidNames', ...
        'Value must be empty or a cell array of character vectors.');
end
end

function columnRows = getColumnRows(DynamicTable, vectorChainNames, rowIndices)
% getColumnRows - Get the requested rows of a column.
%
% vectorChainNames lists the column name first and the names of its
% VectorIndex columns after it, the outermost index last. A column without
% an index returns its rows as an array, or as a struct or table with one
% array per member for a compound column. A ragged column returns a cell
% array with one cell per row, nested once per index level.
vectorChain = cell(size(vectorChainNames));
for iVector = 1:numel(vectorChainNames)
    vectorChain{iVector} = getColumnVector(DynamicTable, vectorChainNames{iVector});
end

if isscalar(vectorChain)
    columnRows = orientRows(vectorChain{1}, readRows(vectorChain{1}, rowIndices));
else
    columnRows = getRaggedRows(vectorChain, rowIndices);
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

function selected = getRaggedRows(vectorChain, rowIndices)
% getRaggedRows - Get rows of a ragged column with one read per level.
%
% vectorChain lists the column's VectorData first and its VectorIndex objects
% after it, the outermost index last. Each level is read once, over the span
% of elements that the requested rows cover, and the rows are then sliced
% from those windows in memory. A column read from file therefore costs one
% read per level, whatever the number of rows and elements.
%
% selected is a cell array with one cell per requested row. For a doubly
% ragged column, each cell holds a cell array with one cell per element.

% Offsets are computed by subtraction, which saturates for unsigned integers.
rowIndices = double(rowIndices);

numLevels = numel(vectorChain);
windows = cell(1, numLevels);
% Element k of windows{iLevel} is element windowOffsets(iLevel) + k of that level.
windowOffsets = zeros(1, numLevels);

% Read the index levels from the outermost down. levelRows holds the rows
% requested from the current level.
levelRows = rowIndices;
hasEmptyDataRow = false;
for iLevel = numLevels:-1:2
    indexVector = vectorChain{iLevel};
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

dataVector = vectorChain{1};
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

[numSubscripts, rowAxis] = getRowDimension(dataVector);
ragged = struct( ...
    'Windows', {windows}, ...
    'WindowOffsets', windowOffsets, ...
    'DataVector', dataVector, ...
    'Rank', numSubscripts, ...
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
        block = selectRows(ragged.Windows{1}, elementRows - ragged.WindowOffsets(1), ...
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

function values = readIndexValues(indexVector, rowsToRead)
% readIndexValues - Read elements of a VectorIndex as a double column vector.
if isa(indexVector.data, 'types.untyped.DataStub') || isa(indexVector.data, 'types.untyped.DataPipe')
    values = indexVector.data.load(rowsToRead);
else
    values = indexVector.data(rowsToRead);
end
values = double(values(:));
end

function block = readRows(vector, rowIndices)
% readRows - Read rows of a column, leaving the rows along the column's row axis.
[numSubscripts, rowAxis] = getRowDimension(vector);
block = selectRows(vector.data, rowIndices, numSubscripts, rowAxis);
end

function selected = orientRows(vector, block)
% orientRows - Put the row axis first for a DataPipe column.
%
% A DataPipe can hold its rows along any axis. The table needs them along
% the first axis, or its variables would have unequal heights.
if isa(vector.data, 'types.untyped.DataPipe')
    selected = permute(block, circshift(1:ndims(block), -(vector.data.axis-1)));
else
    selected = block;
end
end

function [numSubscripts, rowAxis] = getRowDimension(vector)
% getRowDimension - Number of subscripts used to index a column, and the one that selects rows.
data = vector.data;
if isa(data, 'types.untyped.DataStub') || isa(data, 'types.untyped.DataPipe')
    if isa(data, 'types.untyped.DataStub')
        dataSize = data.dims;
    else
        dataSize = data.internal.maxSize;
    end
    if length(dataSize) == 2 && dataSize(2) == 1
        % A column vector is indexed with one subscript.
        numSubscripts = 1;
    else
        numSubscripts = length(dataSize);
    end
else
    if iscolumn(data)
        % A column vector is indexed with one subscript.
        numSubscripts = 1;
    elseif istable(data)
        % A compound column held as a table is indexed by row only.
        numSubscripts = 1;
    else
        numSubscripts = ndims(data);
    end
end

if isa(data, 'types.untyped.DataPipe')
    rowAxis = data.axis;
else
    rowAxis = numSubscripts;
end
end

function selected = selectRows(data, rowIndices, numSubscripts, rowAxis)
% selectRows - Select rows of in-memory or file-backed column data.
%
% The same indexing reads a window from the column and slices rows from
% that window.
subscripts = repmat({':'}, 1, numSubscripts);
subscripts{rowAxis} = rowIndices;

if (isstruct(data) && isscalar(data)) || istable(data)
    if istable(data)
        selected = table();
        fields = data.Properties.VariableNames;
    else
        selected = struct();
        fields = fieldnames(data);
    end

    for iField = 1:length(fields)
        fieldName = fields{iField};
        memberData = data.(fieldName);
        selected.(fieldName) = memberData(subscripts{:});
    end
else
    selected = data(subscripts{:});
end
end

function rowIndices = getRowIndicesById(DynamicTable, requestedIds)
% getRowIndicesById - Row index of each requested value of the id column.
if isa(DynamicTable.id.data, 'types.untyped.DataStub')...
        || isa(DynamicTable.id.data, 'types.untyped.DataPipe')
    ids = DynamicTable.id.data.load();
else
    ids = DynamicTable.id.data;
end
[isIdFound, rowIndices] = ismember(requestedIds, ids);
assert(all(isIdFound), 'NWB:DynamicTable:GetRow:InvalidId',...
    'Invalid ids found. If you wish to use row indices directly, remove the `useId` flag.');
end

function validateRowIndices(dynamicTable, rowIndices)
% validateRowIndices - Error when a row index exceeds the table height.
    tableHeight = types.util.dynamictable.internal.getTableHeight(dynamicTable);

    assert(all(rowIndices <= tableHeight), ...
        'NWB:DynamicTable:GetRow:RowOutOfBounds', ...
        'Requested row index (%s) exceeds the DynamicTable height of %d.', ...
        strjoin(compose('%d', rowIndices(rowIndices > tableHeight) ), ', '), tableHeight);
end

function ME = createInvalidShapeError(columnName)
% createInvalidShapeError - Error for a column whose array does not have the table rows along
% its first or last dimension.
    ME = MException('NWB:DynamicTable:InvalidVectorDataShape', ...
            sprintf( ['Array data for column "%s" has a shape which does ', ...
                      'not match the number of rows in the dynamic table.'], columnName ));
end
