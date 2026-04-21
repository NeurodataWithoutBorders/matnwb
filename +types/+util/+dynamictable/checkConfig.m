function checkConfig(DynamicTable, ignoreList)
% CHECKCONFIG Check a DynamicTable for valid column registration and shape.
%
%   checkConfig(DYNAMICTABLE) runs without error if DYNAMICTABLE is
%   configured correctly.
%
%   checkConfig(DYNAMICTABLE, IGNORELIST) skips columns named in the
%   IGNORELIST cell array when checking for registration in `colnames` and
%   when comparing column row counts.
%
%   A properly configured DynamicTable meets the following criteria:
%   1) All materialized columns are listed in `colnames`, except those in
%      IGNORELIST.
%   2) The row counts of all checked columns are consistent. For ragged
%      columns, this follows VectorIndex links to the outermost index.
%   3) Compound columns have a consistent height across all fields.
%   4) All rows have a corresponding id. If none exist, this function
%      creates them.
%   5) No infinite VectorIndex reference loops exist.
    
    arguments
        DynamicTable
        ignoreList (1,:) cell = {};
    end

    detectedColumnNames = getDetectedColumnNames(DynamicTable);
    % Remove ignored columns before any validation so that columns
    % intentionally omitted from colnames do not trigger ColumnNamesMismatch.
    if ~isempty(ignoreList)
        detectedColumnNames = detectedColumnNames(~ismember(detectedColumnNames, ignoreList));
    end

    if isempty(DynamicTable.colnames)
        assert(isempty(detectedColumnNames), ...
            'NWB:DynamicTable:CheckConfig:ColumnNamesMismatch', ...
            'All Vector Data/Index columns must have their name ordered in the `colnames` property.');
        return;
    end

    DynamicTable.colnames = types.util.dynamictable.validateColnames(DynamicTable.colnames);
    columns = DynamicTable.colnames;

    missingColumnNames = setdiff(detectedColumnNames, columns, 'stable');
    assert(isempty(missingColumnNames), ...
        'NWB:DynamicTable:CheckConfig:ColumnNamesMismatch', ...
        ['All materialized DynamicTable columns must be listed in `colnames`.\n' ...
        'Missing from `colnames`: %s'], ...
        strjoin(missingColumnNames, ', '));

    % do not check specified columns - useful for classes that build on DynamicTable class
    columns = columns(~ismember(columns, ignoreList));

    if isempty(columns)
        return
    end

    columnHeights = zeros(length(columns), 1);
    columnNames = strings(length(columns), 1);
    for iCol = 1:length(columns)
        [columnHeight, columnName] = types.util.dynamictable.internal.getColumnRowHeight( ...
            DynamicTable, columns{iCol});
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

    if isempty(DynamicTable.id)
        types.util.dynamictable.internal.initDynamicTableId(DynamicTable, tableHeight);
        return;
    end

    numIds = types.util.dynamictable.internal.getColumnHeight(DynamicTable.id);
    assert(tableHeight == numIds, ...
        'NWB:DynamicTable:CheckConfig:InvalidId', ...
        'Special column `id` of DynamicTable needs to match the detected height of %d. Found %d IDs.', ...
        tableHeight, numIds);
end

function names = getDetectedColumnNames(DynamicTable)
    % scan the entire dynamic table for columns that may or may not be
    % registered.

    names = {};
    tableProps = properties(DynamicTable);
    for iProp = 1:length(tableProps)
        propName = tableProps{iProp};
        propValue = DynamicTable.(propName);
        if isMaterializedColumn(propValue)
            names{end+1} = propName;
        end
    end

    vectorNames = DynamicTable.vectordata.keys();
    for iVector = 1:length(vectorNames)
        vectorName = vectorNames{iVector};
        Vector = DynamicTable.vectordata.get(vectorName);
        if isMaterializedColumn(Vector)
            names{end+1} = vectorName;
        end
    end
    names = unique(names, 'stable');
end

function tf = isMaterializedColumn(value)
    isVectorData = isa(value, 'types.hdmf_common.VectorData') ...
        || isa(value, 'types.core.VectorData');
    isVectorIndex = isa(value, 'types.hdmf_common.VectorIndex') ...
        || isa(value, 'types.core.VectorIndex');
    tf = ~isempty(value) && isVectorData && ~isVectorIndex;
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
