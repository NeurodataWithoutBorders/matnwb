function addVarargColumn(dynamicTable, columnName, vectorData)

    arguments
        dynamicTable (1,1) {matnwb.common.validation.mustBeDynamicTable}
    end

    arguments (Repeating)
        columnName (1,1) string
        vectorData (1,1) {matnwb.common.validation.mustBeVectorData}
    end

    % Use cellstr so brace-indexing of column names below is valid.
    newColumnNames = cellstr([columnName{:}]);
    newVectorData = cell2struct(vectorData, newColumnNames, 2); % 2nd dim because vectorData is a row vector
    storageTargets = resolveStorageTargets(dynamicTable, newColumnNames, vectorData);

    % Check if any of the new columns already exist in the table
    existingCols = getExistingColumns(dynamicTable, newColumnNames, storageTargets);
    assert(isempty(existingCols), ...
        'NWB:DynamicTable:AddColumn:ColumnExists', ...
        'Column(s) { %s } already exist in the table', strjoin(existingCols, ', '));

    % Check if this is the first column being added (no existing columns and no id data)
    isFirstColumn = isempty(dynamicTable.colnames) && ...
        (isempty(dynamicTable.id) || isempty(dynamicTable.id.data));

    % get current table height - assume id length reflects table height
    if ~isempty(dynamicTable.colnames)
        tableHeight = types.util.dynamictable.internal.getColumnHeight(dynamicTable.id);
    end

    % If adding the first column, initialize the id with 0-indexed values
    if isFirstColumn && ~isempty(newColumnNames)
        % Determine the height of the first column
        firstColName = newColumnNames{1};
        indexName = getIndexInSet(newVectorData, firstColName);
        if isempty(indexName)
            firstColData = newVectorData.(firstColName);
        else
            firstColData = newVectorData.(indexName);
        end

        newTableHeight = types.util.dynamictable.internal.getColumnHeight(firstColData);
        types.util.dynamictable.internal.initDynamicTableId(dynamicTable, newTableHeight);
        tableHeight = newTableHeight;
    end

    for iColumn = 1:length(newColumnNames)
        newColumnName = newColumnNames{iColumn};
        newColumnVector = newVectorData.(newColumnName);
        % check height match before adding column
        if ~isempty(dynamicTable.colnames)
            indexName = getIndexInSet(newVectorData, newColumnName);

            if isempty(indexName)
                heightColumn = newColumnVector;
            else
                heightColumn = newVectorData.(indexName);
            end
            currentColumnHeight = types.util.dynamictable.internal.getColumnHeight(heightColumn);

            validateColumnHeight(newColumnName, currentColumnHeight, tableHeight)
        end
        assignColumn(dynamicTable, newColumnName, newColumnVector, storageTargets{iColumn});
        updateColnames(dynamicTable, newColumnName, newColumnVector)
    end
end

function storageTargets = resolveStorageTargets(dynamicTable, columnNames, columnData)
    storageTargets = cell(size(columnNames));
    for i = 1:length(columnNames)
        storageTargets{i} = types.util.dynamictable.resolveColumnStorage( ...
            dynamicTable, columnNames{i}, columnData{i});
    end
end

function existingCols = getExistingColumns(dynamicTable, newColumnNames, storageTargets)
    existingCols = {};

    if ~isempty(dynamicTable.colnames)
        existingCols = intersect(newColumnNames, dynamicTable.colnames);
    end

    for i = 1:length(newColumnNames)
        newColumnName = newColumnNames{i};
        if any(strcmp(existingCols, newColumnName))
            continue;
        end

        switch storageTargets{i}
            case 'property'
                if ~isempty(dynamicTable.(newColumnName))
                    existingCols{end+1} = newColumnName; %#ok<AGROW>
                end
            case 'vectordata'
                if isa(dynamicTable.vectordata, 'types.untyped.Set') ...
                        && dynamicTable.vectordata.isKey(newColumnName)
                    existingCols{end+1} = newColumnName; %#ok<AGROW>
                end
        end
    end
end

function assignColumn(dynamicTable, columnName, columnValue, storageTarget)
    assert(any(strcmp(storageTarget, {'property', 'vectordata'})), ...
        'NWB:DynamicTable:AddColumn:InternalError', ...
        'Unrecognized storage target `%s` for column `%s`.', ...
        storageTarget, columnName);

    switch storageTarget
        case 'property'
            dynamicTable.(columnName) = columnValue;
        case 'vectordata'
            dynamicTable.vectordata.set(columnName, columnValue);
    end
end

function updateColnames(dynamicTable, newColumnName, newColumnVector)
    % Skip update if new column name is already present in colnames. Column
    % names for schema-defined columns are added to the colnames property
    % automatically via property post-set hooks.
    if any(strcmp(dynamicTable.colnames, newColumnName))
        return
    end

    % Update colnames property if the column vector being added is not a vector index.
    if ~isa(newColumnVector, 'types.hdmf_common.VectorIndex') || isa(newColumnVector, 'types.core.VectorIndex')
        dynamicTable.colnames{end+1} = newColumnName;
    end
end

function indexName = getIndexInSet(inputStruct, inputName)
    arguments
        inputStruct (1,1) struct
        inputName {mustBeTextScalar}
    end

    % wrap input set with an empty dynamic table
    dynamicTable = types.hdmf_common.DynamicTable();
    % convert input structure to a set
    columnNames = fieldnames(inputStruct);
    for iColumn = 1:length(columnNames)
        columnName = columnNames{iColumn};
        dynamicTable.vectordata.set(columnName, inputStruct.(columnName));
    end
    % use dynamic table function to get index name
    indexName = types.util.dynamictable.getIndex(dynamicTable, inputName);
end

function validateColumnHeight(columnName, currentColumnHeight, tableHeight)
    arguments
        columnName {mustBeTextScalar}
        currentColumnHeight (1,1) double
        tableHeight (1,1) double
    end

    if currentColumnHeight ~= tableHeight
        error('NWB:DynamicTable:AddColumn:MissingRows', ...
            'Column `%s` has detected height %d, but the table height is %d.', ...
            columnName, currentColumnHeight, tableHeight)
    end
end
