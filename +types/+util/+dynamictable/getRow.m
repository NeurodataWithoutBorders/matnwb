function subTable = getRow(dynamicTable, rowIndices, varargin)
%GETROW get row for dynamictable
% Index is a scalar 0-based index of the expected row.
% optional keyword argument "columns" allows for only grabbing certain
%   columns instead of returning all columns.
% optional keyword `id` allows for row filtering by user-defined `id`
%   instead of row index.
% The returned value is a set of output arguments in the order of
% `colnames` or "columns" keyword argument if one exists.

    arguments
        dynamicTable (1,1) {matnwb.common.validation.mustBeDynamicTable}
        rowIndices {mustBeNumeric, mustBeInteger, mustBeVector}
    end
    arguments (Repeating)
        varargin
    end

    parser = inputParser;
    addParameter(parser, 'columns', dynamicTable.colnames, @(x)iscellstr(x));
    addParameter(parser, 'useId', false, @(x)islogical(x) && isscalar(x));
    parse(parser, varargin{:});

    columns = parser.Results.columns;
    row = cell(1, length(columns));

    if parser.Results.useId
        assert(~isempty(dynamicTable.id), ...
            'NWB:DynamicTable:GetRow:MissingId', ...
            'Cannot retrieve rows by `id` because the DynamicTable has no `id` column.');
        rowIndices = getIndById(dynamicTable, rowIndices);
    else
        validateattributes(rowIndices, {'numeric'}, {'positive', 'vector'});
        validateRowIndices(dynamicTable, rowIndices);
    end

    for iColumn = 1:length(columns)
        columnName = columns{iColumn};

        indexNames = {columnName};
        while true
            indexName = types.util.dynamictable.getIndex(dynamicTable, indexNames{end});
            if isempty(indexName)
                break;
            end
            indexNames{end+1} = indexName;
        end
    
        row{iColumn} = select(dynamicTable, indexNames, rowIndices);
    
        if ~istable(row{iColumn})
            if iscolumn(row{iColumn})
                % keep column vectors as is
            elseif isrow(row{iColumn})
                row{iColumn} = row{iColumn} .'; % transpose row vectors
            elseif ndims(row{iColumn}) >= 2 % i.e nd array where ndims >= 2
                % permute arrays to place last dimension first
                arraySize = size(row{iColumn});
                numRows = numel(rowIndices);
    
                isRowDim = arraySize == numRows;
                if sum(isRowDim) == 1
                    if ~(isRowDim(1) || isRowDim(end))
                        throw( invalidVectorDataShapeError(columnName) )
                    end
                elseif sum(isRowDim) > 1
                    if isRowDim(1) && isRowDim(end)
                        % Last dimension takes precedence
                        isRowDim(1:end-1) = false;
                        warning('NWB:DynamicTable:VectorDataAmbiguousSize', ...
                            ['The length of the first and last dimensions of ', ...
                             'VectorData for column "%s" match the number of ', ...
                             'rows in the dynamic table. Data is rearranged based on ', ...
                             'the last dimension, assuming it corresponds with the table rows.'], columnName)
                    elseif isRowDim(1)
                        isRowDim(2:end) = false;
                    elseif isRowDim(end)
                        isRowDim(1:end-1) = false;
                    else
                        throw( invalidVectorDataShapeError(columnName) )
                    end
                end
                row{iColumn} = permute(row{iColumn}, [find(isRowDim), find(~isRowDim)]);
            end
        end
    
        % cell-wrap single multidimensional matrices to prevent invalid
        % MATLAB tables
        if isscalar(rowIndices) && ~iscell(row{iColumn}) && ~istable(row{iColumn}) && ~isscalar(row{iColumn})
            row{iColumn} = row(iColumn);
        end
    
        % convert compound data type scalar struct into an array of
        % structs.
        if isscalar(row{iColumn}) && isstruct(row{iColumn})
            structNames = fieldnames(row{iColumn});
            scalarStruct = row{iColumn};
            rowStruct = row{iColumn}; % same as scalarStruct to maintain the field names.
            for iRow = 1:length(rowIndices)
                for iField = 1:length(structNames)
                    fieldName = structNames{iField};
                    fieldData = scalarStruct.(fieldName);
                    rowStruct(iRow).(fieldName) = fieldData(iRow);
                end
            end
            row{iColumn} = rowStruct .';
        end
    end

    if isempty(columns)
        subTable = table('Size', [numel(rowIndices), 0], 'VariableTypes', {}, 'VariableNames', {});
    else
        subTable = table(row{:}, 'VariableNames', columns);
    end
end

function selected = select(dynamicTable, columnIndexStack, matrixIndices)
% recursive function which consumes the colIndStack and produces a nested
% cell array.
    arguments
        dynamicTable (1,1) {matnwb.common.validation.mustBeDynamicTable}
        columnIndexStack (1,:) cell
        matrixIndices {mustBeNumeric, mustBeInteger, mustBeVector}
    end

    columnName = columnIndexStack{end};
    if isprop(dynamicTable, columnName)
        vectorData = dynamicTable.(columnName);
    elseif isprop(dynamicTable, 'vectorindex') && dynamicTable.vectorindex.isKey(columnName) % Schema version < 2.3.0
        vectorData = dynamicTable.vectorindex.get(columnName);
    else
        vectorData = dynamicTable.vectordata.get(columnName);
    end
    
    if isscalar(columnIndexStack)
        if isa(vectorData.data, 'types.untyped.DataStub') || ...
                isa(vectorData.data,'types.untyped.DataPipe')
            if isa(vectorData.data, 'types.untyped.DataStub')
                refProp = vectorData.data.dims;
            else
                refProp = vectorData.data.internal.maxSize;
            end
            if length(refProp) == 2 && refProp(2) == 1
                % catch row vector
                rank = 1;
            else
                rank = length(refProp);
            end
        else
            if iscolumn(vectorData.data)
                % catch row vector
                rank = 1;
            elseif istable(vectorData.data)
                rank = 1;
            else
                rank = ndims(vectorData.data);
            end
        end
    
        selectInd = repmat({':'}, 1, rank);
        if isa(vectorData.data, 'types.untyped.DataPipe')
            selectInd{vectorData.data.axis} = matrixIndices;
        else
            selectInd{end} = matrixIndices;
        end
    
        if (isstruct(vectorData.data) && isscalar(vectorData.data)) || istable(vectorData.data)
            if istable(vectorData.data)
                selected = table();
                fields = vectorData.data.Properties.VariableNames;
            else
                selected = struct();
                fields = fieldnames(vectorData.data);
            end
    
            for iField = 1:length(fields)
                fieldName = fields{iField};
                columnData = vectorData.data.(fieldName);
                selected.(fieldName) = columnData(selectInd{:});
            end
        else
            selected = vectorData.data(selectInd{:});
        end
    
        % shift dimensions of non-row vectors. otherwise will result in
        % invalid MATLAB table with uneven column height
        if isa(vectorData.data, 'types.untyped.DataPipe')
            selected = permute(selected, ...
                circshift(1:ndims(selected), -(vectorData.data.axis-1)));
        end
    else
        assert(isa(vectorData, 'types.hdmf_common.VectorIndex') || isa(vectorData, 'types.core.VectorIndex'),...
            'NWB:DynamicTable:GetRow:InternalError',...
            'Internal VectorIndex Stack is not using VectorIndex objects!');
        if isa(vectorData.data, 'types.untyped.DataStub') || isa(vectorData.data, 'types.untyped.DataPipe')
            stopInds = uint64(vectorData.data.load(matrixIndices));
        else
            stopInds = uint64(vectorData.data(matrixIndices));
        end
    
        startIndexIndices = matrixIndices - 1;
        zeroMask = startIndexIndices == 0;
        startInds = zeros(size(startIndexIndices));
        if ~isempty(startIndexIndices(~zeroMask))
            if isa(vectorData.data, 'types.untyped.DataStub') || isa(vectorData.data, 'types.untyped.DataPipe')
                startInds(~zeroMask) = vectorData.data.load(startIndexIndices(~zeroMask));
            else
                startInds(~zeroMask) = vectorData.data(startIndexIndices(~zeroMask));
            end
        end
        startInds = startInds + 1;
    
        selected = cell(length(matrixIndices), 1);
        for iRange = 1:length(matrixIndices)
            startInd = startInds(iRange);
            stopInd = stopInds(iRange);
            selected{iRange} = select(dynamicTable,...
                columnIndexStack(1:(end-1)),...
                startInd:stopInd);
        end
    end
end

function rowIndices = getIndById(dynamicTable, idValues)
    arguments
        dynamicTable (1,1) {matnwb.common.validation.mustBeDynamicTable}
        idValues {mustBeNumeric, mustBeInteger, mustBeVector}
    end

    if isa(dynamicTable.id.data, 'types.untyped.DataStub')...
            || isa(dynamicTable.id.data, 'types.untyped.DataPipe')
        ids = dynamicTable.id.data.load();
    else
        ids = dynamicTable.id.data;
    end
    [idMatch, rowIndices] = ismember(idValues, ids);
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

function exception = invalidVectorDataShapeError(columnName)
    arguments
        columnName {mustBeTextScalar}
    end

    exception = MException('NWB:DynamicTable:InvalidVectorDataShape', ...
            sprintf(['Array data for column "%s" has a shape which do ', ...
                     'not match the number of rows in the dynamic table.'], columnName));
end
