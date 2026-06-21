function addCategory(alignedTable, categoryName, categoryTable, options)
%ADDCATEGORY Add one or more category tables to an AlignedDynamicTable.

    arguments
        alignedTable (1,1) types.hdmf_common.AlignedDynamicTable
        categoryName (1,:) cell
        categoryTable (1,:) cell
    end

    arguments
        options.Replace (1,1) logical = false
    end

    validateCategoryInputs(categoryName, categoryTable)

    categoryNames = [categoryName{:}];
    validateUniqueInputNames(categoryNames)

    for iCategory = 1:numel(categoryNames)
        currentTable = categoryTable{iCategory};
        types.util.dynamictable.checkConfig(currentTable);
    end

    [parentHeight, parentHasHeight] = ...
        types.util.aligneddynamictable.internal.getTableHeightInfo(alignedTable);

    for iCategory = 1:numel(categoryNames)
        currentName = categoryNames(iCategory);
        currentTable = categoryTable{iCategory};

        [categoryHeight, categoryHasHeight] = ...
            types.util.aligneddynamictable.internal.getTableHeightInfo(currentTable);

        if parentHasHeight && ~categoryHasHeight
            types.util.aligneddynamictable.internal.initializeTableId(currentTable, parentHeight)
            categoryHeight = parentHeight;
        elseif ~parentHasHeight && categoryHasHeight
            types.util.aligneddynamictable.internal.initializeTableId(alignedTable, categoryHeight)
            parentHeight = categoryHeight;
            parentHasHeight = true;
        elseif ~parentHasHeight && ~categoryHasHeight
            types.util.aligneddynamictable.internal.initializeTableId(currentTable, 0)
            types.util.aligneddynamictable.internal.initializeTableId(alignedTable, 0)
            categoryHeight = 0;
            parentHeight = 0;
            parentHasHeight = true;
        end

        validateCategoryHeight(currentName, categoryHeight, parentHeight)
        assignCategory(alignedTable, currentName, currentTable, Replace=options.Replace)
        syncCategoryName(alignedTable, currentName)
    end
end

function validateCategoryInputs(categoryName, categoryTable)
    assert(~isempty(categoryName), ...
        'NWB:AlignedDynamicTable:AddCategory:NoData', ...
        'Provide at least one category name and DynamicTable pair.')

    assert(numel(categoryName) == numel(categoryTable), ...
        'NWB:AlignedDynamicTable:AddCategory:NameTableMismatch', ...
        'Category names and category tables must be provided in pairs.')

    for iCategory = 1:numel(categoryName)
        currentName = categoryName{iCategory};
        assert(isa(currentName, 'string') && isscalar(currentName), ...
            'NWB:AlignedDynamicTable:AddCategory:InvalidCategoryName', ...
            'Category names must be scalar strings.')

        matnwb.common.validation.mustBeDynamicTable(categoryTable{iCategory});
    end
end

function validateUniqueInputNames(categoryNames)
    uniqueNames = unique(categoryNames, 'stable');
    hasDuplicateNames = numel(uniqueNames) ~= numel(categoryNames);

    assert(~hasDuplicateNames, ...
        'NWB:AlignedDynamicTable:AddCategory:DuplicateInputNames', ...
        'Each category name can only be specified once.')
end

function validateCategoryHeight(categoryName, categoryHeight, parentHeight)
    if categoryHeight ~= parentHeight
        error('NWB:AlignedDynamicTable:AddCategory:MissingRows', ...
            'Category `%s` has detected height %d, but the parent table height is %d.', ...
            categoryName, categoryHeight, parentHeight)
    end
end

function assignCategory(alignedTable, categoryName, categoryTable, options)
    arguments
        alignedTable (1,1) types.hdmf_common.AlignedDynamicTable
        categoryName (1,1) string
        categoryTable (1,1) {matnwb.common.validation.mustBeDynamicTable}
        options.Replace (1,1) logical = false
    end

    isSchemaCategory = types.util.aligneddynamictable.internal.isSchemaDefinedCategory( ...
        alignedTable, categoryName);
    if isSchemaCategory
        if ~options.Replace && ~isempty(alignedTable.(categoryName))
            error('NWB:AlignedDynamicTable:AddCategory:CategoryExists', ...
                'Category `%s` already exists in the table.', categoryName)
        end
        alignedTable.(categoryName) = categoryTable;
    else
        alignedTable.dynamictable.set( ...
            categoryName, categoryTable, ...
            FailIfKeyExists=~options.Replace, ...
            FailOnInvalidType=true);
    end
end

function syncCategoryName(alignedTable, categoryName)
    categories = types.util.aligneddynamictable.validateCategories(alignedTable.categories);
    if isempty(categories)
        alignedTable.categories = {char(categoryName)};
        return
    end

    if ~any(strcmp(categories, categoryName))
        categories{end+1} = char(categoryName);
        alignedTable.categories = categories;
    end
end
