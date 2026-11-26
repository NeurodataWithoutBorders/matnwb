function addVarargColumn(DynamicTable, varargin)

% parse inputs
p = inputParser();
p.KeepUnmatched = true;
p.StructExpand = false;
parse(p, varargin{:});
newColNames = DynamicTable.validate_colnames(fieldnames(p.Unmatched));
newVectorData = p.Unmatched;
[storageTargets, storageNames] = resolveStorageTargets(DynamicTable, newColNames);

% Check if any of the new columns already exist in the table
existingCols = getExistingColumns( ...
    DynamicTable, newColNames, storageTargets, storageNames);
assert(isempty(existingCols), ...
    'NWB:DynamicTable:AddColumn:ColumnExists', ...
    'Column(s) { %s } already exist in the table', strjoin(existingCols, ', '));

assertIndexColumnsHaveTargets(newVectorData)

% Check if this is the first column being added (no existing columns and no id data)
isFirstColumn = isempty(DynamicTable.colnames) && ...
    (isempty(DynamicTable.id) || isempty(DynamicTable.id.data));

% The id column sets the table height whenever the table has ids, including a
% table that has ids but no columns yet.
if ~isFirstColumn
    tableHeight = types.util.dynamictable.internal.getColumnHeight(DynamicTable.id);
end

indexColumns = collectIndexColumns(DynamicTable, newVectorData);

% If adding the first column, initialize the id with 0-indexed values
if isFirstColumn && ~isempty(newColNames)
    % Determine the height of the first column
    firstColData = getHeightColumn(newVectorData, newColNames{1}, indexColumns);

    newTableHeight = types.util.dynamictable.internal.getColumnHeight(firstColData);
    types.util.dynamictable.internal.initDynamicTableId(DynamicTable, newTableHeight);
    tableHeight = newTableHeight;
end

for i = 1:length(newColNames)
    new_cn = newColNames{i};
    new_cv = newVectorData.(new_cn);
    % check height match before adding column
    heightColumn = getHeightColumn(newVectorData, new_cn, indexColumns);
    currentColumnHeight = types.util.dynamictable.internal.getColumnHeight(heightColumn);
    validateColumnHeight(new_cn, currentColumnHeight, tableHeight)

    assignColumn( ...
        DynamicTable, new_cn, new_cv, storageTargets{i}, storageNames{i});
    updateColnames(DynamicTable, new_cn, new_cv)
end
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

function indexColumns = collectIndexColumns(dynamicTable, newVectorData)
    % The VectorIndex columns that can index a new column, as a struct array
    % with the fields name and column, in the order they are searched: the
    % new columns first, then the index columns of the table, which hold an
    % index that was added in an earlier call.
    names = reshape(fieldnames(newVectorData), 1, []);
    columns = cellfun(@(name) newVectorData.(name), names, 'UniformOutput', false);

    vectorNames = reshape(dynamicTable.vectordata.keys(), 1, []);
    vectorColumns = cellfun(@(name) dynamicTable.vectordata.get(name), vectorNames, ...
        'UniformOutput', false);

    % Index columns that the schema defines are stored on properties of the
    % class. The properties of the object also list one dynamic property for
    % each entry of vectordata, which the keys above cover.
    propertyNames = reshape(properties(class(dynamicTable)), 1, []);
    propertyColumns = cellfun(@(name) dynamicTable.(name), propertyNames, ...
        'UniformOutput', false);

    names = [names, vectorNames, propertyNames];
    columns = [columns, vectorColumns, propertyColumns];
    isIndex = cellfun(@isVectorIndexWithTarget, columns);
    indexColumns = struct('name', names(isIndex), 'column', columns(isIndex));
end

function tf = isVectorIndexWithTarget(column)
    tf = isVectorIndex(column) && ~isempty(column.target);
end

function tf = isVectorIndex(column)
    tf = isa(column, 'types.hdmf_common.VectorIndex') ...
        || isa(column, 'types.core.VectorIndex');
end

function assertIndexColumnsHaveTargets(newVectorData)
    % An index column names the column it indexes through its target.
    % Without a target it cannot be matched to a data column.
    columnNames = fieldnames(newVectorData);
    for i = 1:numel(columnNames)
        column = newVectorData.(columnNames{i});
        if isVectorIndex(column) && isempty(column.target)
            error("NWB:DynamicTable:AddColumn:MissingIndexTarget", ...
                "Index column `%s` has no target. Set its `target` property to a " + ...
                "`types.untyped.ObjectView` of the column it indexes.", columnNames{i})
        end
    end
end

function heightColumn = getHeightColumn(newVectorData, columnName, indexColumns)
    % The column whose height is the number of table rows for the new column
    % COLUMNNAME: its outermost index, whatever the depth of the ragged
    % column, or the column itself when it has no index.
    heightColumn = newVectorData.(columnName);
    visitedNames = {};
    iIndex = findIndexOf(columnName, heightColumn, indexColumns);
    while ~isempty(iIndex)
        indexName = indexColumns(iIndex).name;
        assert(~any(strcmp(visitedNames, indexName)), ...
            'NWB:DynamicTable:CheckConfig:InfiniteReferenceLoop', ...
            'Invalid Table shape detected: There is an infinite loop in your VectorIndex objects.');
        visitedNames{end+1} = indexName; %#ok<AGROW>
        heightColumn = indexColumns(iIndex).column;
        iIndex = findIndexOf(indexName, heightColumn, indexColumns);
    end
end

function iIndex = findIndexOf(columnName, column, indexColumns)
    % The position in INDEXCOLUMNS of the first VectorIndex that targets
    % COLUMN, or empty when none does. A target that has a path in a file is
    % matched by the column name that ends the path, as
    % types.util.dynamictable.getIndex matches it; any other target is
    % matched by the object it holds.
    iIndex = [];
    for i = 1:numel(indexColumns)
        target = indexColumns(i).column.target;
        if target.has_path()
            isTarget = endsWith(target.path, ['/' columnName]);
        else
            isTarget = ~isempty(target.target) && target.target == column;
        end
        if isTarget
            iIndex = i;
            return
        end
    end
end

function validateColumnHeight(columnName, currentColumnHeight, tableHeight)
    if currentColumnHeight ~= tableHeight
        error('NWB:DynamicTable:AddColumn:MissingRows', ...
            'Column `%s` has detected height %d, but the table height is %d.', ...
            columnName, currentColumnHeight, tableHeight)       
    end
end
