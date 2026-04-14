function checkConfig(dynamicTable, ignoreList)
    % CHECKCONFIG Given a DynamicTable object, this functions checks for proper
    % DynamicTable configuration
    %
    %   checkConfig(DYNAMICTABLE) runs without error if the DynamicTable is
    %   configured correctly
    %
    %   checkConfig(DYNAMICTABLE,IGNORELIST) performs checks on columns not in
    %   IGNORELIST cell array
    %
    %
    %  A properly configured DynamicTable should meet the following criteria:
    %  1) The length of all columns in the dynamic table is the same.
    %  2) All rows have a corresponding id. If none exist, this function creates them.
    %  3) No index loops exist.
    arguments
        dynamicTable (1,1) {matnwb.common.validation.mustBeDynamicTable}
        ignoreList = {}
    end

    ignoreList = normalizeIgnoreList(ignoreList);

    if isempty(dynamicTable.colnames)
        assert(isempty(getDetectedColumnNames(dynamicTable)), ...
            'NWB:DynamicTable:CheckConfig:ColumnNamesMismatch', ...
            'All Vector Data/Index columns must have their name ordered in the `colnames` property.');
        return;
    end

    % remove null characters from column names
    dynamicTable.colnames = cleanColumnNames(dynamicTable.colnames);

    % do not check specified columns - useful for classes that build on DynamicTable class
    columns = setdiff(dynamicTable.colnames, ignoreList);

    if isempty(columns)
        return
    end

    columnHeights = zeros(length(columns), 1);
    columnNames = strings(length(columns), 1);
    for iCol = 1:length(columns)
        [columnHeight, columnName] = types.util.dynamictable.internal.getColumnRowHeight( ...
            dynamicTable, columns{iCol});
        columnHeight = unique(columnHeight);

        assert(isscalar(columnHeight), ...
            'NWB:DynamicTable:CheckConfig:InvalidShape', ...
            'Invalid compound column detected: compound column heights must all be the same.');
        columnHeights(iCol) = columnHeight;
        columnNames(iCol) = columnName;
    end

    tableHeight = unique(columnHeights);
    if isempty(tableHeight)
        tableHeight = 0;
    end

    formatSpec = sprintf('  %%-%ds %%d', max(strlength(columnNames)));
    assert(isscalar(tableHeight), ...
        'NWB:DynamicTable:CheckConfig:InvalidShape', ...
        ['Invalid table: all columns must have the same height (number of rows).\n\n' ...
        'Detected column heights:\n' ...
        strjoin( compose(formatSpec, columnNames, columnHeights), newline) ]);

    if isempty(dynamicTable.id)
        types.util.dynamictable.internal.initDynamicTableId(dynamicTable, tableHeight);
        return;
    end

    numIds = types.util.dynamictable.internal.getColumnHeight(dynamicTable.id);
    assert(tableHeight == numIds, ...
        'NWB:DynamicTable:CheckConfig:InvalidId', ...
        'Special column `id` of DynamicTable needs to match the detected height of %d. Found %d IDs.', ...
        tableHeight, numIds);
end

function names = getDetectedColumnNames(dynamicTable)
    % scan the entire dynamic table for columns that may or may not be
    % registered.

    names = {};
    tableProps = properties(dynamicTable);
    for iProp = 1:length(tableProps)
        propName = tableProps{iProp};
        propValue = dynamicTable.(propName);
        if ~isempty(propValue) ...
                && (isa(propValue, 'types.core.VectorData') || isa(propValue, 'types.hdmf_common.VectorData'))
            names{end+1} = propName;
        end
    end

    vectorNames = dynamicTable.vectordata.keys();
    for iVector = 1:length(vectorNames)
        vectorName = vectorNames{iVector};
        vectorData = dynamicTable.vectordata.get(vectorName);
        if isa(vectorData, 'types.hdmf_common.VectorData') || isa(vectorData, 'types.core.VectorData')
            if isa(vectorData.data, 'types.untyped.DataStub')
                isDataEmpty = any(vectorData.data.dims == 0);
            elseif isa(vectorData.data, 'types.untyped.DataPipe')
                isDataEmpty = any(size(vectorData.data) == 0);
            else
                isDataEmpty = isempty(vectorData.data);
            end
            if ~isDataEmpty
                names{end+1} = vectorName;
            end
        end
    end
end

function colnames = cleanColumnNames(colnames)
    %CLEANCOLUMNNAMES removes the null character from column names.
    assert(iscellstr(colnames) || ischar(colnames), ...
        'NWB:DynamicTable:CheckConfig:InvalidColumnNames', ...
        'Column names must be a cell array of strings or a character array.');
    isScalarChar = ischar(colnames);
    if isScalarChar
        colnames = {colnames};
    end

    for iColumn = 1:length(colnames)
        column = colnames{iColumn};
        column = column(0 ~= double(column));
        colnames{iColumn} = column;
    end

    if isScalarChar
        colnames = colnames{1};
    end
end

function ignoreList = normalizeIgnoreList(ignoreList)
    if ischar(ignoreList)
        ignoreList = {ignoreList};
    elseif isstring(ignoreList)
        ignoreList = cellstr(ignoreList);
    end

    assert(iscellstr(ignoreList), ...
        'NWB:DynamicTable:CheckConfig:InvalidIgnoreList', ...
        'Ignore list must be text or a cell array of character vectors.');
end
