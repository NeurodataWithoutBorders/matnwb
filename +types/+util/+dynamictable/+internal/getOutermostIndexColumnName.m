function outermostIndexColumnName = getOutermostIndexColumnName(dynamicTable, columnName)
% getOutermostIndexColumnName - Resolve a column name to the outermost index column.
%
% Note: Relevant for ragged array columns

    arguments
        dynamicTable
        columnName {mustBeTextScalar}
    end

    columnName = char(columnName);

    columnHistory = {};
    outermostIndexColumnName = columnName;
    while true
        indexName = types.util.dynamictable.getIndex(dynamicTable, outermostIndexColumnName);
        if isempty(indexName)
            return;
        end
        assert(~any(strcmp(columnHistory, indexName)), ...
            'NWB:DynamicTable:CheckConfig:InfiniteReferenceLoop', ...
            'Invalid Table shape detected: There is an infinite loop in your VectorIndex objects.');
        columnHistory{end+1} = indexName; %#ok<AGROW>
        outermostIndexColumnName = indexName;
    end
end
