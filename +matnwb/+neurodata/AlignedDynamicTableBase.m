classdef (Abstract) AlignedDynamicTableBase < handle
% AlignedDynamicTableBase - Non-generated base class for AlignedDynamicTable.
%
% This class owns custom behavior that the generated schema class
% cannot express: category table registration and lookup, category name
% validation, and row-height consistency between the parent table and all
% category tables.

    properties (Abstract)
        categories
        dynamictable
    end

    methods
        function addCategory(obj, categoryName, categoryTable)
        % addCategory - Add one or more category tables.
        %
        % Syntax:
        %   alignedDynamicTable.addCategory(categoryName, categoryTable)
        %   alignedDynamicTable.addCategory(categoryNameA, categoryTableA, ...)
        %
        % This method assigns each category table, registers the category
        % name, and ensures the category table height matches the parent
        % AlignedDynamicTable height.
        %
        % Input Arguments:
        %  - categoryName (string) -
        %    A name for the category.
        %
        %  - categoryTable (types.hdmf_common.DynamicTable) -
        %    A dynamic table to add as a category table. Note: Nested
        %    AlignedDynamicTables are not supported.

            arguments
                obj (1,1) matnwb.neurodata.AlignedDynamicTableBase
            end
            arguments (Repeating)
                categoryName (1,1) string
                categoryTable (1,1) {matnwb.common.validation.mustBeDynamicTable, mustNotBeAlignedDynamicTable}
            end

            categoryNames = [categoryName{:}];

            assert(~isempty(categoryName), ...
                'NWB:AlignedDynamicTable:AddCategory:NoData', ...
                'Provide at least one category name and DynamicTable pair.')
            obj.assertUniqueCategoryNames(categoryNames)

            [parentHeight, parentHasHeight] = matnwb.neurodata.internal.table.getTableHeight(obj);

            for iCategory = 1:numel(categoryNames)
                currentName = categoryNames(iCategory);
                currentTable = categoryTable{iCategory};

                [parentHeight, parentHasHeight, categoryHeight] = ...
                    obj.establishAlignedTableHeight( ...
                    currentTable, parentHeight, parentHasHeight);

                obj.assertCategoryHeightMatchesParent(currentName, categoryHeight, parentHeight)
                obj.assignCategoryTable(currentName, currentTable)
                obj.registerCategoryName(currentName)
            end
        end

        function categoryTable = getCategory(obj, categoryName)
        % getCategory - Return a schema-defined or custom category table.
        %
        % Syntax:
        %   categoryTable = alignedDynamicTable.getCategory(categoryName)
        %
        % This method resolves schema-defined categories stored as object
        % properties and custom categories stored in the constrained
        % dynamictable group.
        %
        % Input Arguments:
        %  - categoryName (string) -
        %    A name for the category.

            arguments
                obj (1,1) matnwb.neurodata.AlignedDynamicTableBase
                categoryName (1,1) string
            end

            categoryTable = obj.getCategoryTable(categoryName);
        end
    end

    % Hidden because this method is normally called by generated
    % validation/export flow, but remains callable for explicit consistency
    % checks.
    methods (Hidden)
        function ensureAlignedTableConsistency(obj)
        % ensureAlignedTableConsistency - Ensure category and height consistency.
        %
        % This method delegates ordinary DynamicTable validation to
        % types.util.dynamictable.checkConfig, then validates category
        % registration and category table heights. It may also initialize
        % missing id datasets when the table height can be inferred from the
        % parent table or a category table. Category registry mismatches are
        % warnings while reading existing files, but errors during normal
        % validation/export.

            arguments
                obj (1,1) matnwb.neurodata.AlignedDynamicTableBase
            end

            types.util.dynamictable.checkConfig(obj);

            categoryTableNames = obj.getMaterializedCategoryNames();

            obj.assertNoNestedAlignedDynamicTable(categoryTableNames);

            if isempty(obj.categories)
                if ~isempty(categoryTableNames)
                    obj.handleCategoryNamesMismatch( ...
                        ['All materialized AlignedDynamicTable category tables must be ', ...
                        'listed in the `categories` property.']);
                end
                return
            end

            categoryNames = obj.validateCategoryNames(obj.categories);
            missingCategoryNames = setdiff(categoryTableNames, categoryNames, 'stable');
            if ~isempty(missingCategoryNames)
                obj.handleCategoryNamesMismatch( ...
                    ['All materialized AlignedDynamicTable category tables must be listed ', ...
                    'in `categories`.\nMissing from `categories`: %s'], ...
                    strjoin(missingCategoryNames, ', '));
            end

            if isempty(categoryNames)
                return
            end

            [parentHeight, parentHasHeight] = matnwb.neurodata.internal.table.getTableHeight(obj);
            materializedRegisteredNames = intersect(categoryNames, categoryTableNames, 'stable');
            categoryHeights = zeros(size(materializedRegisteredNames));

            for iCategory = 1:numel(materializedRegisteredNames)
                categoryName = materializedRegisteredNames{iCategory};
                categoryTable = obj.getCategoryTable(categoryName);
                types.util.dynamictable.checkConfig(categoryTable);

                [parentHeight, parentHasHeight, categoryHeight, categoryHasHeight] = ...
                    obj.establishAlignedTableHeight( ...
                    categoryTable, parentHeight, parentHasHeight);

                if categoryHasHeight
                    categoryHeights(iCategory) = categoryHeight;
                end
            end

            unmaterializedCategoryNames = setdiff(categoryNames, categoryTableNames, 'stable');
            if ~isempty(unmaterializedCategoryNames) && parentHasHeight && parentHeight > 0
                obj.handleCategoryNamesMismatch( ...
                    ['The `categories` property lists category table(s) that have not ', ...
                    'been added to the AlignedDynamicTable: %s.\nAdd the missing ', ...
                    'table(s) with the addCategory method (or by setting the ', ...
                    'corresponding schema category property), or list categories only ', ...
                    'before the table has rows.'], ...
                    strjoin(unmaterializedCategoryNames, ', '));
            end

            assert(isempty(categoryHeights) || all(categoryHeights == parentHeight), ...
                'NWB:AlignedDynamicTable:ValidateAlignedTableConsistency:InvalidCategoryShape', ...
                ['Invalid AlignedDynamicTable: all category tables must have the ', ...
                'same height as the parent table.'])
        end
    end

    methods (Access = protected, Hidden)
        function categoryNames = getSchemaDefinedCategories(obj) %#ok<MANU>
        % getSchemaDefinedCategories - Return schema-defined category names.
        %
        % The class generation pipeline extends this method for every
        % subclass. Subclasses with schema-defined category properties append
        % those names to the list returned by this base implementation.
            categoryNames = string.empty(1, 0);
        end

        function ensureCategoryNameRegistered(obj, categoryName)
        % ensureCategoryNameRegistered - Register a populated schema category.
        %
        % This method is added as a generated property post-set hook for any
        % schema-defined category property by the class generation pipeline.
        %
        % Generated property setters call this after assigning schema-defined
        % category table properties, for example:
        %   intracellularRecordingsTable.electrodes = electrodesTable;
        %
        % This ensures "electrodes" is added to the categories property if
        % it was not assigned during table construction.
        %
        % During file read, this method does not mutate categories.

            arguments
                obj (1,1) matnwb.neurodata.AlignedDynamicTableBase
                categoryName (1,:) char
            end

            if isempty(obj.(categoryName))
                return
            end

            if strcmp(types.util.validationContext(), 'read')
                return % No mutation on read
            end

            obj.registerCategoryName(categoryName)
        end
    
        function categoryNames = validateCategoryNames(~, categoryNames)
        % validateCategoryNames - Normalize category names and reject duplicates.

            categoryNames = types.util.dynamictable.normalizeColnames(categoryNames);
            validateUniqueCategoryNames(categoryNames)
        end
    end

    methods (Access = private)
        function tf = isSchemaDefinedCategory(obj, categoryName)
            arguments
                obj (1,1) matnwb.neurodata.AlignedDynamicTableBase
                categoryName (1,1) string
            end

            schemaCategoryNames = obj.getSchemaDefinedCategories();
            tf = any(schemaCategoryNames == categoryName);
        end

        function tf = categoryExists(obj, categoryName)
            arguments
                obj (1,1) matnwb.neurodata.AlignedDynamicTableBase
                categoryName (1,1) string
            end

            if obj.isSchemaDefinedCategory(categoryName)
                tf = ~isempty(obj.(categoryName));
            else
                tf = ~isempty(obj.dynamictable) && obj.dynamictable.isKey(categoryName);
            end
        end

        function categoryTable = getCategoryTable(obj, categoryName)
            arguments
                obj (1,1) matnwb.neurodata.AlignedDynamicTableBase
                categoryName (1,1) string
            end

            if obj.isSchemaDefinedCategory(categoryName)
                if isempty(obj.(categoryName))
                    error('NWB:AlignedDynamicTable:CategoryNotFound', ...
                        'Category `%s` has not been added to the table.', categoryName)
                end
                categoryTable = obj.(categoryName);
            elseif isempty(obj.dynamictable) || ~obj.dynamictable.isKey(categoryName)
                error('NWB:AlignedDynamicTable:CategoryNotFound', ...
                    'Category `%s` has not been added to the table.', categoryName)
            else
                categoryTable = obj.dynamictable.get(categoryName);
            end
        end

        function categoryNames = getMaterializedCategoryNames(obj)
            arguments
                obj (1,1) matnwb.neurodata.AlignedDynamicTableBase
            end

            categoryNames = string.empty(1, 0);
            schemaCategoryNames = obj.getSchemaDefinedCategories();

            for iCategory = 1:numel(schemaCategoryNames)
                categoryName = schemaCategoryNames(iCategory);
                if isprop(obj, categoryName) && ~isempty(obj.(categoryName))
                    categoryNames(end+1) = categoryName; %#ok<AGROW>
                end
            end

            if ~isempty(obj.dynamictable)
                customCategoryNames = string(obj.dynamictable.keys());
                categoryNames = [categoryNames, customCategoryNames];
            end

            categoryNames = cellstr(unique(categoryNames, 'stable'));
        end

        function [parentHeight, parentHasHeight, categoryHeight, categoryHasHeight] = ...
                establishAlignedTableHeight(obj, categoryTable, parentHeight, parentHasHeight)
        % establishAlignedTableHeight - Establish compatible parent/category heights.
        %
        % If exactly one table has an established height, this method
        % initializes ids for the other table to that height. If neither
        % table has a height, it initializes both as empty tables so later
        % checks can treat height as established.

            [categoryHeight, categoryHasHeight] = matnwb.neurodata.internal.table.getTableHeight(categoryTable);

            if parentHasHeight && ~categoryHasHeight
                matnwb.neurodata.internal.table.initializeTableId(categoryTable, parentHeight);
                categoryHeight = parentHeight;
                categoryHasHeight = true;
            elseif ~parentHasHeight && categoryHasHeight
                matnwb.neurodata.internal.table.initializeTableId(obj, categoryHeight);
                parentHeight = categoryHeight;
                parentHasHeight = true;
            elseif ~parentHasHeight && ~categoryHasHeight
                matnwb.neurodata.internal.table.initializeTableId(categoryTable, 0);
                matnwb.neurodata.internal.table.initializeTableId(obj, 0);
                [categoryHeight, parentHeight] = deal(0);
                [categoryHasHeight, parentHasHeight] = deal(true);
            end
        end

        function assertNoNestedAlignedDynamicTable(obj, categoryNames)
            for iCategory = 1:numel(categoryNames)
                categoryTable = obj.getCategoryTable(string(categoryNames{iCategory}));
                mustNotBeAlignedDynamicTable(categoryTable)
            end
        end

        function assignCategoryTable(obj, categoryName, categoryTable)
            arguments
                obj (1,1) matnwb.neurodata.AlignedDynamicTableBase
                categoryName (1,1) string
                categoryTable (1,1) {matnwb.common.validation.mustBeDynamicTable}
            end

            if obj.categoryExists(categoryName)
                error('NWB:AlignedDynamicTable:AddCategory:CategoryExists', ...
                    'Category `%s` already exists in the table.', categoryName)
            end

            if obj.isSchemaDefinedCategory(categoryName)
                obj.(categoryName) = categoryTable;
            else
                obj.dynamictable.set( ...
                    categoryName, categoryTable, ...
                    FailIfKeyExists=true, ...
                    FailOnInvalidType=true);
            end
        end

        function registerCategoryName(obj, categoryName)
            categoryNames = obj.validateCategoryNames(obj.categories);
            if isempty(categoryNames)
                obj.categories = {char(categoryName)};
                return
            end

            if ~any(strcmp(categoryNames, categoryName))
                categoryNames{end+1} = char(categoryName);
                obj.categories = categoryNames;
            end
        end
    end

    methods (Static, Access = private)
        function assertUniqueCategoryNames(categoryNames)
            uniqueNames = unique(categoryNames, 'stable');
            hasDuplicateNames = numel(uniqueNames) ~= numel(categoryNames);

            assert(~hasDuplicateNames, ...
                'NWB:AlignedDynamicTable:AddCategory:DuplicateInputNames', ...
                'Each category name can only be specified once.')
        end

        function assertCategoryHeightMatchesParent(categoryName, categoryHeight, parentHeight)
            if categoryHeight ~= parentHeight
                error('NWB:AlignedDynamicTable:AddCategory:MissingRows', ...
                    'Category `%s` has detected height %d, but the parent table height is %d.', ...
                    categoryName, categoryHeight, parentHeight)
            end
        end

        function handleCategoryNamesMismatch(message, varargin)
            if strcmp(types.util.validationContext(), 'read')
                warning('NWB:AlignedDynamicTable:ValidateAlignedTableConsistency:CategoryNamesMismatch', ...
                    message, varargin{:});
            else
                error('NWB:AlignedDynamicTable:ValidateAlignedTableConsistency:CategoryNamesMismatch', ...
                    message, varargin{:});
            end
        end
    end
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

function mustNotBeAlignedDynamicTable(value)
    assert(~isa(value, 'matnwb.neurodata.AlignedDynamicTableBase'), ...
        'NWB:AlignedDynamicTable:NestedAlignedTable', ...
        ['Category tables of AlignedDynamicTable cannot themselves be ', ...
        'AlignedDynamicTable instances.'])
end
