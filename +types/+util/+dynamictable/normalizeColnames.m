function colnames = normalizeColnames(colnames)
%NORMALIZECOLNAMES Normalize DynamicTable column names without uniqueness checks.

    if isempty(colnames)
        return
    end

    assert(iscellstr(colnames) || isstring(colnames) || ischar(colnames), ...
        'NWB:DynamicTable:InvalidColumnNames', ...
        'Column names must be a cell array of character vectors.');

    if isstring(colnames)
        colnames = cellstr(colnames);
    elseif ischar(colnames)
        colnames = {colnames};
    end

    for iColumn = 1:length(colnames)
        column = colnames{iColumn};
        column = column(0 ~= double(column));
        colnames{iColumn} = column;
    end
end
