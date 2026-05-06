function validateUniqueColnames(colnames)
%VALIDATEUNIQUECOLNAMES Validate that DynamicTable column names are unique.

    uniqueNames = unique(colnames, 'stable');
    hasDuplicateColumnNames = numel(uniqueNames) ~= numel(colnames);
    if ~hasDuplicateColumnNames
        return
    end

    if strcmp(types.util.validationContext(), 'read')
        warning('NWB:DynamicTable:DuplicateColumnNames', ...
            'Column names in `colnames` must be unique.');
    else
        error('NWB:DynamicTable:DuplicateColumnNames', ...
            'Column names in `colnames` must be unique.');
    end
end
