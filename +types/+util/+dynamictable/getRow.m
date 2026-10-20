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
% array with one cell per row, nested once per index level: the outermost
% index gives the element range of each row, and the function recurses into
% the chain below it for the elements of that range.
column = vectorChainNames{end};
if isprop(DynamicTable, column)
    Vector = DynamicTable.(column);
elseif isprop(DynamicTable, 'vectorindex') && DynamicTable.vectorindex.isKey(column) % Schema version < 2.3.0
    Vector = DynamicTable.vectorindex.get(column);
else
    Vector = DynamicTable.vectordata.get(column);
end

if isscalar(vectorChainNames)
    if isa(Vector.data, 'types.untyped.DataStub') || ...
            isa(Vector.data,'types.untyped.DataPipe')
        if isa(Vector.data, 'types.untyped.DataStub')
            dataSize = Vector.data.dims;
        else
            dataSize = Vector.data.internal.maxSize;
        end
        if length(dataSize) == 2 && dataSize(2) == 1
            % A column vector is indexed with one subscript.
            numSubscripts = 1;
        else
            numSubscripts = length(dataSize);
        end
    else
        if iscolumn(Vector.data)
            % A column vector is indexed with one subscript.
            numSubscripts = 1;
        elseif istable(Vector.data)
            % A compound column held as a table is indexed by row only.
            numSubscripts = 1;
        else
            numSubscripts = ndims(Vector.data);
        end
    end
    
    subscripts = repmat({':'}, 1, numSubscripts);
    if isa(Vector.data, 'types.untyped.DataPipe')
        subscripts{Vector.data.axis} = rowIndices;
    else
        subscripts{end} = rowIndices;
    end
    
    if (isstruct(Vector.data) && isscalar(Vector.data)) || istable(Vector.data)
        if istable(Vector.data)
            columnRows = table();
            fields = Vector.data.Properties.VariableNames;
        else
            columnRows = struct();
            fields = fieldnames(Vector.data);
        end
        
        for iField = 1:length(fields)
            fieldName = fields{iField};
            memberData = Vector.data.(fieldName);
            columnRows.(fieldName) = memberData(subscripts{:});
        end
    else
        columnRows = Vector.data(subscripts{:});
    end

    % A DataPipe can hold its rows along any axis. The table needs them along
    % the first axis, or its variables would have unequal heights.
    if isa(Vector.data, 'types.untyped.DataPipe')
        columnRows = permute(columnRows, ...
            circshift(1:ndims(columnRows), -(Vector.data.axis-1)));
    end
else
    assert(isa(Vector, 'types.hdmf_common.VectorIndex') || isa(Vector, 'types.core.VectorIndex'),...
        'NWB:DynamicTable:GetRow:InternalError',...
        'Internal VectorIndex Stack is not using VectorIndex objects!');
    if isa(Vector.data, 'types.untyped.DataStub') || isa(Vector.data, 'types.untyped.DataPipe')
        stopInds = uint64(Vector.data.load(rowIndices));
    else
        stopInds = uint64(Vector.data(rowIndices));
    end

    startIndInd = rowIndices - 1;
    zeroMask = startIndInd == 0;
    startInds = zeros(size(startIndInd));
    if ~isempty(startIndInd(~zeroMask))
        if isa(Vector.data, 'types.untyped.DataStub') || isa(Vector.data, 'types.untyped.DataPipe')
            startInds(~zeroMask) = Vector.data.load(startIndInd(~zeroMask));
        else
            startInds(~zeroMask) = Vector.data(startIndInd(~zeroMask));
        end
    end
    startInds = startInds + 1;

    columnRows = cell(length(rowIndices), 1);
    for iRange = 1:length(rowIndices)
        startInd = startInds(iRange);
        stopInd = stopInds(iRange);
        columnRows{iRange} = getColumnRows(DynamicTable,...
            vectorChainNames(1:(end-1)),...
            startInd:stopInd);
    end
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
