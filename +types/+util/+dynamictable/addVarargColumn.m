function addVarargColumn(dynamicTable, columnName, vectorData)

    arguments
        dynamicTable (1,1) {matnwb.common.validation.mustBeDynamicTable}
    end

    arguments (Repeating)
        columnName (1,1) string
        vectorData (1,1) {matnwb.common.validation.mustBeVectorData}
    end

    newColumnNames = [columnName{:}];
    newVectorData = cell2struct(vectorData, newColumnNames, 2); % 2nd dim because vectorData is row vector

    % Check if any of the new columns already exist in the table
    if ~isempty(dynamicTable.colnames)
        existingCols = intersect(newColumnNames, dynamicTable.colnames);
        assert(isempty(existingCols), ...
            'NWB:DynamicTable:AddColumn:ColumnExists', ...
            'Column(s) { %s } already exist in the table', strjoin(existingCols, ', '));
    end

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
        if 8 == exist('types.hdmf_common.VectorIndex', 'class')
            if ~isa(newColumnVector, 'types.hdmf_common.VectorIndex')
                dynamicTable.colnames{end+1} = newColumnName;
            end
        else %legacy case
            if ~isa(newColumnVector, 'types.core.VectorIndex')
                dynamicTable.colnames{end+1} = newColumnName;
            end
        end
        dynamicTable.vectordata.set(newColumnName, newColumnVector);
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
