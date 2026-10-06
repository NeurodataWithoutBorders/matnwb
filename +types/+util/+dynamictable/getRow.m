function subTable = getRow(DynamicTable, rowIndices, varargin)
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
validateattributes(rowIndices, {'numeric'}, {'integer', 'vector'});

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

% Names read from a file are column cell arrays.
columns = reshape(p.Results.columns, 1, []);
categories = reshape(p.Results.categories, 1, []);
columnData = cell(1, numel(columns) + numel(categories));

if p.Results.useId
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
        elseif ndims(columnData{iColumn}) >= 2 % i.e nd array where ndims >= 2
            % permute arrays to place last dimension first
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

    % cell-wrap single multidimensional matrices to prevent invalid
    % MATLAB tables
    if isscalar(rowIndices) && ~iscell(columnData{iColumn}) ...
            && ~istable(columnData{iColumn}) && ~isscalar(columnData{iColumn})
        columnData{iColumn} = columnData(iColumn);
    end

    % convert compound data type scalar struct into an array of
    % structs.
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

function columnRows = getColumnRows(DynamicTable, vectorChainNames, rowIndices)
% recursive function which consumes vectorChainNames and produces a nested
% cell array.
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
            % catch row vector
            numSubscripts = 1;
        else
            numSubscripts = length(dataSize);
        end
    else
        if iscolumn(Vector.data)
            %catch row vector
            numSubscripts = 1;
        elseif istable(Vector.data)
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

    % shift dimensions of non-row vectors. otherwise will result in
    % invalid MATLAB table with uneven column height
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
    tableHeight = types.util.dynamictable.internal.getTableHeight(dynamicTable);

    assert(all(rowIndices <= tableHeight), ...
        'NWB:DynamicTable:GetRow:RowOutOfBounds', ...
        'Requested row index (%s) exceeds the DynamicTable height of %d.', ...
        strjoin(compose('%d', rowIndices(rowIndices > tableHeight) ), ', '), tableHeight);
end

function ME = createInvalidShapeError(columnName)
    ME = MException('NWB:DynamicTable:InvalidVectorDataShape', ...
            sprintf( ['Array data for column "%s" has a shape which does ', ...
                      'not match the number of rows in the dynamic table.'], columnName ));
end
