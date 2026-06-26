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
        if ~isempty(detectedColumnNames)
            handleColumnNamesMismatch( ...
                'All Vector Data/Index columns must have their name ordered in the `colnames` property.');
        end
        return;
    end
    if ~types.util.dynamictable.internal.isColnamesTextContainer(DynamicTable.colnames) ...
            && matnwb.common.validation.isReadContext()
        return
    end
    columns = types.util.dynamictable.normalizeColnames(DynamicTable.colnames);
    if ~matnwb.common.validation.isReadContext()
        % Skip on file read, this might mutate colnames
        types.util.dynamictable.validateUniqueColnames(columns);
    end

    missingColumnNames = setdiff(detectedColumnNames, columns, 'stable');
    if ~isempty(missingColumnNames)
        handleColumnNamesMismatch( ...
            ['All materialized DynamicTable columns must be listed in `colnames`.\n' ...
            'Missing from `colnames`: %s'], ...
            strjoin(missingColumnNames, ', '));
    end

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

        if ~isscalar(columnHeight)
            matnwb.common.validation.reportSchemaViolation( ...
                'NWB:DynamicTable:CheckConfig:InvalidShape', ...
                'Invalid compound column detected: compound column heights must all be the same.');
            return
        end
        columnHeights(iCol) = columnHeight;
        columnNames(iCol) = columnName;
    end

    tableHeight = unique(columnHeights);
    if isempty(tableHeight)
        tableHeight = 0;
    end

    formatSpec = sprintf('  %%-%ds %%d', max(strlength(columnNames)));
    if ~isscalar(tableHeight)
        detectedHeightsText = strjoin( ...
            compose(formatSpec, columnNames, columnHeights), newline);
        matnwb.common.validation.reportSchemaViolation( ...
            'NWB:DynamicTable:CheckConfig:InvalidShape', ...
            sprintf(['Invalid table: all columns must have the same height (number of rows).\n\n', ...
            'Detected column heights:\n%s'], detectedHeightsText));
        return
    end

    if isempty(DynamicTable.id)
        types.util.dynamictable.internal.initDynamicTableId(DynamicTable, tableHeight);
        return;
    end

    numIds = types.util.dynamictable.internal.getColumnHeight(DynamicTable.id);
    if tableHeight ~= numIds
        matnwb.common.validation.reportSchemaViolation( ...
            'NWB:DynamicTable:CheckConfig:InvalidId', ...
            sprintf(['Special column `id` of DynamicTable needs to match ', ...
            'the detected height of %d. Found %d IDs.'], tableHeight, numIds));
        return
    end
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

function handleColumnNamesMismatch(message, varargin)
    matnwb.common.validation.reportSchemaViolation(...
        'NWB:DynamicTable:CheckConfig:ColumnNamesMismatch', ...
        sprintf(message, varargin{:}))
end
