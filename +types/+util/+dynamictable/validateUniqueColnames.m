function validateUniqueColnames(colnames)
%VALIDATEUNIQUECOLNAMES Validate that DynamicTable column names are unique.

    uniqueNames = unique(colnames, 'stable');
    hasDuplicateColumnNames = numel(uniqueNames) ~= numel(colnames);
    if ~hasDuplicateColumnNames
        return
    end

    isDuplicateName = cellfun(@(name) sum(strcmp(colnames, name)) > 1, uniqueNames);
    duplicateNames = uniqueNames(isDuplicateName);
    duplicateNameLabels = strcat('`', duplicateNames, '`');
    duplicateNamesText = strjoin(duplicateNameLabels, ', ');

    if isscalar(duplicateNames)
        columnLabel = 'name';
    else
        columnLabel = 'names';
    end

    message = sprintf( ...
        'Column names in `colnames` must be unique. Duplicate column %s: %s.', ...
        columnLabel, duplicateNamesText);

    if strcmp(types.util.validationContext(), 'read')
        warning('NWB:DynamicTable:DuplicateColumnNames', ...
            message);
    else
        error('NWB:DynamicTable:DuplicateColumnNames', ...
            message);
    end
end
