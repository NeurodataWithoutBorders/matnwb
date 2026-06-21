function checkConfig(alignedTable)
%CHECKCONFIG Check an AlignedDynamicTable for valid category alignment.

    arguments
        alignedTable (1,1) types.hdmf_common.AlignedDynamicTable
    end

    types.util.dynamictable.checkConfig(alignedTable);

    materializedCategoryNames = ...
        types.util.aligneddynamictable.internal.getMaterializedCategoryNames(alignedTable);

    if isempty(alignedTable.categories)
        if ~isempty(materializedCategoryNames)
            handleCategoryNamesMismatch( ...
                ['All materialized AlignedDynamicTable category tables must be ', ...
                'listed in the `categories` property.']);
        end
        return
    end

    categories = types.util.aligneddynamictable.validateCategories(alignedTable.categories);
    missingCategoryNames = setdiff(materializedCategoryNames, categories, 'stable');
    if ~isempty(missingCategoryNames)
        handleCategoryNamesMismatch( ...
            ['All materialized AlignedDynamicTable category tables must be listed ', ...
            'in `categories`.\nMissing from `categories`: %s'], ...
            strjoin(missingCategoryNames, ', '));
    end

    if isempty(categories)
        return
    end

    [parentHeight, parentHasHeight] = ...
        types.util.aligneddynamictable.internal.getTableHeightInfo(alignedTable);
    materializedRegisteredNames = intersect(categories, materializedCategoryNames, 'stable');
    categoryHeights = zeros(size(materializedRegisteredNames));

    for iCategory = 1:numel(materializedRegisteredNames)
        categoryName = materializedRegisteredNames{iCategory};
        categoryTable = types.util.aligneddynamictable.internal.getCategoryTable( ...
            alignedTable, categoryName);
        types.util.dynamictable.checkConfig(categoryTable);

        [categoryHeight, categoryHasHeight] = ...
            types.util.aligneddynamictable.internal.getTableHeightInfo(categoryTable);
        if parentHasHeight && ~categoryHasHeight
            types.util.aligneddynamictable.internal.initializeTableId(categoryTable, parentHeight);
            categoryHeight = parentHeight;
            categoryHasHeight = true;
        elseif ~parentHasHeight && categoryHasHeight
            types.util.aligneddynamictable.internal.initializeTableId(alignedTable, categoryHeight);
            parentHeight = categoryHeight;
            parentHasHeight = true;
        elseif ~parentHasHeight && ~categoryHasHeight
            types.util.aligneddynamictable.internal.initializeTableId(categoryTable, 0);
            types.util.aligneddynamictable.internal.initializeTableId(alignedTable, 0);
            categoryHeight = 0;
            parentHeight = 0;
            categoryHasHeight = true;
            parentHasHeight = true;
        end

        if categoryHasHeight
            categoryHeights(iCategory) = categoryHeight;
        end
    end

    unmaterializedCategoryNames = setdiff(categories, materializedCategoryNames, 'stable');
    if ~isempty(unmaterializedCategoryNames) && parentHasHeight && parentHeight > 0
        handleCategoryNamesMismatch( ...
            ['All category names in `categories` must match materialized category tables.', ...
            '\nMissing category table(s): %s'], ...
            strjoin(unmaterializedCategoryNames, ', '));
    end

    assert(isempty(categoryHeights) || all(categoryHeights == parentHeight), ...
        'NWB:AlignedDynamicTable:CheckConfig:InvalidCategoryShape', ...
        ['Invalid AlignedDynamicTable: all category tables must have the ', ...
        'same height as the parent table.'])
end

function handleCategoryNamesMismatch(message, varargin)
    if strcmp(types.util.validationContext(), 'read')
        warning('NWB:AlignedDynamicTable:CheckConfig:CategoryNamesMismatch', ...
            message, varargin{:});
    else
        error('NWB:AlignedDynamicTable:CheckConfig:CategoryNamesMismatch', ...
            message, varargin{:});
    end
end
