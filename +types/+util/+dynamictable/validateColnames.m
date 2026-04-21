function colnames = validateColnames(colnames)
%VALIDATECOLNAMES Validate and normalize DynamicTable column names.

    if isempty(colnames)
        return
    end

    colnames = cleanColumnNames(colnames);
    if ischar(colnames)
        colnames = {colnames};
    end

    assert(iscellstr(colnames) || isstring(colnames), ...
        'NWB:DynamicTable:InvalidColumnNames', ...
        'Column names must be a cell array of character vectors.');

    if isstring(colnames)
        colnames = cellstr(colnames);
    end

    uniqueNames = unique(colnames, 'stable');
    assert(numel(uniqueNames) == numel(colnames), ...
        'NWB:DynamicTable:DuplicateColumnNames', ...
        'Column names in `colnames` must be unique.');
end

function colnames = cleanColumnNames(colnames)
    assert(iscellstr(colnames) || ischar(colnames), ...
        'NWB:DynamicTable:InvalidColumnNames', ...
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
