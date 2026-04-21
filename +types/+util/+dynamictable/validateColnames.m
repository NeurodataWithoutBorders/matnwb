function colnames = validateColnames(colnames)
% VALIDATECOLNAMES Validate and normalize DynamicTable column names.
%
% Input can be a cell array of character vectors, a string array or a
% character vector. Output is a cell array of character vectors.

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

    colnames = cleanColumnNames(colnames);

    uniqueNames = unique(colnames, 'stable');
    assert(numel(uniqueNames) == numel(colnames), ...
        'NWB:DynamicTable:DuplicateColumnNames', ...
        'Column names in `colnames` must be unique.');
end

function colnames = cleanColumnNames(colnames)
    for iColumn = 1:length(colnames)
        column = colnames{iColumn};
        column = column(0 ~= double(column));
        colnames{iColumn} = column;
    end
end
