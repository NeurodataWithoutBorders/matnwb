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
% getRaggedRows - Get rows of a ragged column, reading only the requested elements.
%
% vectorChain lists the column's VectorData first and its VectorIndex objects
% after it, the outermost index last. Each index level is read in one call,
% for exactly the index elements the requested rows need. Data in a file is
% read in one call for exactly the elements of the requested rows, and the
% rows are then taken from that read in memory. Data in memory is indexed
% once per row (see readDataRows).
%
% selected is a cell array with one cell per requested row. For a doubly
% ragged column, each cell holds a cell array with one cell per element.

% Row indices are shifted by subtraction, which saturates for unsigned integers.
rowIndices = double(reshape(rowIndices, 1, []));

numLevels = numel(vectorChain);
% rowStarts{iLevel} and rowStops{iLevel} give the element range, in the
% level below, of each row requested from level iLevel.
rowStarts = cell(1, numLevels);
rowStops = cell(1, numLevels);

% Read the index levels from the outermost down. levelRows lists the rows
% requested from the current level in output order, and after the loop the
% data elements requested from the column.
levelRows = rowIndices;
for iLevel = numLevels:-1:2
    indexVector = vectorChain{iLevel};
    assert(isa(indexVector, 'types.hdmf_common.VectorIndex') || isa(indexVector, 'types.core.VectorIndex'), ...
        'NWB:DynamicTable:GetRow:InternalError', ...
        'Internal VectorIndex Stack is not using VectorIndex objects!');

    [rowStarts{iLevel}, rowStops{iLevel}] = readElementRanges(indexVector, levelRows);
    levelRows = expandRanges(rowStarts{iLevel}, rowStops{iLevel});
end

rowValues = readDataRows(vectorChain{1}, rowStarts{2}, rowStops{2}, levelRows);

% Nest the rows of each level under their rows in the level above. An empty
% row has a stop below its start.
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

% Each row needs index(r) and index(r-1), so neighbouring rows share
% elements. The selection is read sorted and without duplicates, which
% keeps the HDF5 reader on its fast path. index(0) is not stored.
rowsToRead = unique([rowIndices, rowIndices - 1]);
rowsToRead(rowsToRead == 0) = [];
indexValues = readIndexValues(indexVector, rowsToRead);

% Look up each row's stop, and its previous row's stop, in the single read.
% Row 1 has no previous row and keeps its default start of 1.
[~, stopPositions] = ismember(rowIndices, rowsToRead);
stops = reshape(indexValues(stopPositions), size(rowIndices));
hasPreviousRow = rowIndices > 1;
[~, previousPositions] = ismember(rowIndices(hasPreviousRow) - 1, rowsToRead);
starts(hasPreviousRow) = indexValues(previousPositions) + 1;
end

function elements = expandRanges(starts, stops)
% expandRanges - Concatenate the ranges starts(i):stops(i) into one row vector.
hasElements = starts <= stops;
starts = starts(hasElements);
stops = stops(hasElements);
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
% readDataRows - Get the data of ragged rows, one cell per row.
%
% Row i holds data elements starts(i) through stops(i), and elements lists
% the elements of all rows.
%
% A column in memory is indexed once per row, which copies each element
% once. A column in a file is read in one call for the elements of all rows,
% and the rows are then taken from that read in memory.
[numSubscripts, rowAxis] = getRowDimension(dataVector);
% A DataPipe is indexed through its subsref, which reads from the file once
% the pipe is bound to it and from the pipe's own data before that. Both are
% read in blocks, like a DataStub.
isFileBacked = isa(dataVector.data, 'types.untyped.DataStub') ...
    || isa(dataVector.data, 'types.untyped.DataPipe');

if isFileBacked
    elements = unique(elements);
    if isempty(elements)
        % Every row is empty, and the empty rows are read by readEmptyRow.
        block = [];
    else
        block = readRows(dataVector, elements);
    end
    % The elements of a row are consecutive in elements.
    [~, startPositions] = ismember(starts, elements);
end

isEmptyRow = starts > stops;
emptyRow = [];
if any(isEmptyRow)
    emptyRow = readEmptyRow(dataVector);
end

rowValues = cell(numel(starts), 1);
for iRow = 1:numel(starts)
    if isEmptyRow(iRow)
        rowValues{iRow} = emptyRow;
        continue
    end
    if isFileBacked
        blockRows = startPositions(iRow) + (0:(stops(iRow) - starts(iRow)));
        rowBlock = selectRows(block, blockRows, numSubscripts, rowAxis);
    else
        rowBlock = selectRows(dataVector.data, starts(iRow):stops(iRow), numSubscripts, rowAxis);
    end
    rowValues{iRow} = orientRows(dataVector, rowBlock);
end
end

function emptyRow = readEmptyRow(dataVector)
% readEmptyRow - Value of an empty row of a ragged column.
%
% The empty row is read as an empty selection from the column instead of
% taken from a block of rows, so it has the type and shape of a direct read.
% A file-backed column reads its first element to learn the type of an
% empty selection, so a dataset without elements gets an empty of its data
% type instead.
data = dataVector.data;
if isa(data, 'types.untyped.DataStub')
    isEmptyDataset = any(data.dims == 0);
elseif isa(data, 'types.untyped.DataPipe') && data.isBound
    isEmptyDataset = any(size(data) == 0);
else
    % Indexing in-memory data with an empty selection needs no elements.
    isEmptyDataset = false;
end

if isEmptyDataset
    emptyRow = orientRows(dataVector, createEmptyValue(data.dataType));
else
    emptyRow = orientRows(dataVector, readRows(dataVector, zeros(1, 0)));
end
end

function value = createEmptyValue(dataType)
% createEmptyValue - Empty value of the MATLAB type a dataset is read as.
%
% A compound dataset is read as a table with one variable per member, and
% every other dataset as an array. The empty array is 0x0, the shape an
% empty selection of a file-backed column has.
if isstruct(dataType)
    compoundMemberNames = fieldnames(dataType);
    compoundMembers = struct();
    for iMember = 1:numel(compoundMemberNames)
        compoundMembers.(compoundMemberNames{iMember}) = createEmptyArray(dataType.(compoundMemberNames{iMember}), 1);
    end
    value = struct2table(compoundMembers);
else
    value = createEmptyArray(dataType, 0);
end
end

function value = createEmptyArray(matlabType, numColumns)
% createEmptyArray - Empty array with no rows of the MATLAB type a dataset is read as.
%
% The types follow io.parseCompound, which builds the columns of a
% compound dataset without rows the same way.
switch matlabType
    case {'char', 'cell'}
        % Text and non-boolean enums are read as cell arrays.
        value = cell(0, numColumns);
    case 'logical'
        value = false(0, numColumns);
    otherwise
        % Numeric types and the reference classes construct an empty
        % instance from their class name.
        value = feval([matlabType '.empty'], 0, numColumns);
end
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
% The same indexing reads rows from the column and takes rows from a block
% already read from it.
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
