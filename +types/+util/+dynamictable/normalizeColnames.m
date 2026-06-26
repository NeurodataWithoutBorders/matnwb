function colnames = normalizeColnames(colnames)
%NORMALIZECOLNAMES Normalize DynamicTable column names without uniqueness checks.

    if isempty(colnames)
        return
    end

    % This low-level normalizer is intentionally strict. Read-context callers
    % that preserve an invalid value after dtype validation should bypass
    % normalization rather than re-reporting the same schema violation.
    assert(types.util.dynamictable.internal.isColnamesTextContainer(colnames), ...
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
