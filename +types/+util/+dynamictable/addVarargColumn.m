function addVarargColumn(DynamicTable, varargin)

% parse inputs
p = inputParser();
p.KeepUnmatched = true;
p.StructExpand = false;
parse(p, varargin{:});
newColNames = DynamicTable.validate_colnames(fieldnames(p.Unmatched));
newVectorData = p.Unmatched;
[storageTargets, storageNames] = resolveStorageTargets(DynamicTable, newColNames);

% The elements of an EnumData column are stored next to the column. They are
% not a column of the table, so they have no row height and no entry in
% colnames.
isEnumElements = ismember(newColNames, ...
    getNewEnumElementsNames(DynamicTable, newColNames, newVectorData));
newTableColumnNames = newColNames(~isEnumElements);

% Check if any of the new columns already exist in the table
existingCols = getExistingColumns( ...
    DynamicTable, newColNames, storageTargets, storageNames);
assert(isempty(existingCols), ...
    'NWB:DynamicTable:AddColumn:ColumnExists', ...
    'Column(s) { %s } already exist in the table', strjoin(existingCols, ', '));

% Check if this is the first column being added (no existing columns and no id data)
isFirstColumn = isempty(DynamicTable.colnames) && ...
    (isempty(DynamicTable.id) || isempty(DynamicTable.id.data));

% get current table height - assume id length reflects table height
if ~isempty(DynamicTable.colnames)
    tableHeight = types.util.dynamictable.internal.getColumnHeight(DynamicTable.id);
end

% If adding the first column, initialize the id with 0-indexed values
if isFirstColumn && ~isempty(newTableColumnNames)
    % Determine the height of the first column
    firstColName = newTableColumnNames{1};
    indexName = getIndexInSet(newVectorData, firstColName);
    if isempty(indexName)
        firstColData = newVectorData.(firstColName);
    else
        firstColData = newVectorData.(indexName);
    end

    newTableHeight = types.util.dynamictable.internal.getColumnHeight(firstColData);
    types.util.dynamictable.internal.initDynamicTableId(DynamicTable, newTableHeight);
    tableHeight = newTableHeight;
end

for i = 1:length(newColNames)
    new_cn = newColNames{i};
    new_cv = newVectorData.(new_cn);
    % check height match before adding column
    if ~isempty(DynamicTable.colnames) && ~isEnumElements(i)
        indexName = getIndexInSet(newVectorData,new_cn);

        if isempty(indexName)
            heightColumn = new_cv;
        else
            heightColumn = newVectorData.(indexName);
        end
        currentColumnHeight = types.util.dynamictable.internal.getColumnHeight(heightColumn);

        validateColumnHeight(new_cn, currentColumnHeight, tableHeight)
    end
    assignColumn( ...
        DynamicTable, new_cn, new_cv, storageTargets{i}, storageNames{i});
    if ~isEnumElements(i)
        updateColnames(DynamicTable, new_cn, new_cv)
    end
end
end

function elementsNames = getNewEnumElementsNames(dynamicTable, newColumnNames, newVectorData)
    % Return which of the new vectors hold the elements of an EnumData
    % column, where the EnumData column is either new or already in the
    % table.
    newVectors = cellfun(@(name) newVectorData.(name), newColumnNames, ...
        'UniformOutput', false);
    vectorNames = [reshape(dynamicTable.vectordata.keys(), 1, []), reshape(newColumnNames, 1, [])];
    vectors = [reshape(dynamicTable.vectordata.values(), 1, []), reshape(newVectors, 1, [])];

    elementsNames = types.util.dynamictable.internal.getEnumElementsNames( ...
        vectorNames, vectors);
    elementsNames = intersect(elementsNames, newColumnNames, 'stable');
end

function [storageTargets, storageNames] = resolveStorageTargets(dynamicTable, columnNames)
    storageTargets = cell(size(columnNames));
    storageNames = cell(size(columnNames));
    for i = 1:length(columnNames)
        [storageTargets{i}, storageNames{i}] = ...
            types.util.dynamictable.resolveColumnStorage( ...
                dynamicTable, columnNames{i});
    end
end

function existingCols = getExistingColumns( ...
        dynamicTable, newColNames, storageTargets, storageNames)
    existingCols = {};
    
    if ~isempty(dynamicTable.colnames)
        existingCols = intersect(newColNames, dynamicTable.colnames);
    end
    
    for i = 1:length(newColNames)
        newColumnName = newColNames{i};
        if any(strcmp(existingCols, newColumnName))
            continue;
        end
    
        switch storageTargets{i}
            case 'property'
                if ~isempty(dynamicTable.(storageNames{i}))
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

function assignColumn( ...
        DynamicTable, columnName, columnValue, storageTarget, storageName)
    assert(any(strcmp(storageTarget, {'property', 'vectordata'})), ...
        'NWB:DynamicTable:AddColumn:InternalError', ...
        'Unrecognized storage target `%s` for column `%s`.', ...
        storageTarget, columnName);
    
    switch storageTarget
        case 'property'
            DynamicTable.(storageName) = columnValue;
        case 'vectordata'
            DynamicTable.vectordata.set(storageName, columnValue);
    end
end

function updateColnames(DynamicTable, new_cn, new_cv)
    % Skip update if new column name is already present in colnames. Column
    % names for schema-defined columns are added to the colnames property
    % automatically via property post-set hooks.
    if any(strcmp(DynamicTable.colnames, new_cn))
        return
    end

    % Update colnames property if the column vector being added is not a vector index.
    if ~isa(new_cv, 'types.hdmf_common.VectorIndex') || isa(new_cv, 'types.core.VectorIndex')
        % assignColumn will update colnames for schema-defined columns via
        % post set hook. Only add column name to colnames if if is not
        % wlaready added.
        DynamicTable.colnames{end+1} = new_cn;
    end
end

function indexName = getIndexInSet(inputStruct, inputName)
    % wrap input set with an empty dynamic table
    T = types.hdmf_common.DynamicTable();
    % convert input structure to a set
    columnNames = fieldnames(inputStruct);
    for i = 1:length(columnNames)
        T.vectordata.set(columnNames{i},inputStruct.(columnNames{i}));
    end
    % use dynamic table function to get index name
    indexName = types.util.dynamictable.getIndex(T, inputName);
end

function validateColumnHeight(columnName, currentColumnHeight, tableHeight)
    if currentColumnHeight ~= tableHeight
        error('NWB:DynamicTable:AddColumn:MissingRows', ...
            'Column `%s` has detected height %d, but the table height is %d.', ...
            columnName, currentColumnHeight, tableHeight)       
    end
end
