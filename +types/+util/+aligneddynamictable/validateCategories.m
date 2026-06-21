function categories = validateCategories(categories)
%VALIDATECATEGORIES Validate and normalize AlignedDynamicTable category names.

    categories = types.util.dynamictable.normalizeColnames(categories);
    validateUniqueCategoryNames(categories)
end

function validateUniqueCategoryNames(categories)
    uniqueNames = unique(categories, 'stable');
    hasDuplicateNames = numel(uniqueNames) ~= numel(categories);
    if ~hasDuplicateNames
        return
    end

    isDuplicateName = cellfun(@(name) sum(strcmp(categories, name)) > 1, uniqueNames);
    duplicateNames = uniqueNames(isDuplicateName);
    duplicateNameLabels = strcat('`', duplicateNames, '`');
    duplicateNamesText = strjoin(duplicateNameLabels, ', ');

    if isscalar(duplicateNames)
        categoryLabel = 'name';
    else
        categoryLabel = 'names';
    end

    message = sprintf( ...
        'Category names in `categories` must be unique. Duplicate category %s: %s.', ...
        categoryLabel, duplicateNamesText);

    if strcmp(types.util.validationContext(), 'read')
        warning('NWB:AlignedDynamicTable:DuplicateCategoryNames', '%s', message);
    else
        error('NWB:AlignedDynamicTable:DuplicateCategoryNames', '%s', message);
    end
end
