function dynamicTable = DynamicTable(options)

    arguments
        options.NumRows = 1
        options.NumColumns {mustBeLessThanOrEqual(options.NumColumns, 26)} = 1
        options.ColumnNames (1,:) string = missing
    end
    
    if ~ismissing(options.ColumnNames)
        assert(numel(options.ColumnNames) == options.NumColumns)
    else
        columnNames = strings(1, options.NumColumns);
        for i = 1:options.NumColumns
            columnNames(i) = sprintf("Column%s", char(i+64));
        end
    end

    columnData = cell(1, options.NumColumns);
    for i = 1:options.NumColumns
        columnData{i} = types.hdmf_common.VectorData(...
            'description', sprintf('column #%d', i), ...
            'data', randi(10, [1, options.NumRows]));
    end

    columnNvPairs = cat(1, cellstr(columnNames), columnData);

    idColumn = types.hdmf_common.ElementIdentifiers(...
        'data', (0:options.NumRows-1)' );

    dynamicTable = types.hdmf_common.DynamicTable( ...
        'description', 'test table with columns and rows', ...
        'colnames', columnNames, ...
        columnNvPairs{:}, ...
        'id', idColumn);
end
