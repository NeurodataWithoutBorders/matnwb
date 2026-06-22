classdef (Abstract) AlignedDynamicTableBase < handle
% AlignedDynamicTableBase - Handwritten behavior for AlignedDynamicTable.

    properties (Abstract)
        categories
        dynamictable
    end

    methods
        function addCategory(obj, categoryName, categoryTable)
        % addCategory - Add one or more category tables.

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

            [parentHeight, parentHasHeight] = obj.getTableHeightInfo(obj);

            for iCategory = 1:numel(categoryNames)
                currentName = categoryNames(iCategory);
                currentTable = categoryTable{iCategory};

                [parentHeight, parentHasHeight, categoryHeight] = ...
                    obj.establishAlignedTableHeight( ...
                    currentTable, parentHeight, parentHasHeight);

                obj.validateCategoryHeight(currentName, categoryHeight, parentHeight)
                obj.assignCategoryTable(currentName, currentTable)
                obj.addNameToCategories(currentName)
            end
        end

        function validateAlignedTableConsistency(obj)
        % validateAlignedTableConsistency - Validate table and category consistency.

            arguments
                obj (1,1) matnwb.neurodata.AlignedDynamicTableBase
            end

            types.util.dynamictable.checkConfig(obj);

            materializedCategoryNames = obj.getMaterializedCategoryNames();
            obj.validateMaterializedCategoryTablesAreNotAligned(materializedCategoryNames);

            if isempty(obj.categories)
                if ~isempty(materializedCategoryNames)
                    obj.handleCategoryNamesMismatch( ...
                        ['All materialized AlignedDynamicTable category tables must be ', ...
                        'listed in the `categories` property.']);
                end
                return
            end

            categoryNames = obj.validateCategories(obj.categories);
            missingCategoryNames = setdiff(materializedCategoryNames, categoryNames, 'stable');
            if ~isempty(missingCategoryNames)
                obj.handleCategoryNamesMismatch( ...
                    ['All materialized AlignedDynamicTable category tables must be listed ', ...
                    'in `categories`.\nMissing from `categories`: %s'], ...
                    strjoin(missingCategoryNames, ', '));
            end

            if isempty(categoryNames)
                return
            end

            [parentHeight, parentHasHeight] = obj.getTableHeightInfo(obj);
            materializedRegisteredNames = intersect(categoryNames, materializedCategoryNames, 'stable');
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

            unmaterializedCategoryNames = setdiff(categoryNames, materializedCategoryNames, 'stable');
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

        function categoryTable = getCategory(obj, categoryName)
        % getCategory - Return a schema-defined or custom category table.

            arguments
                obj (1,1) matnwb.neurodata.AlignedDynamicTableBase
                categoryName (1,1) string
            end

            categoryTable = obj.getCategoryTable(categoryName);
        end
    end

    methods (Access = protected, Hidden)
        function categoryNames = getSchemaDefinedCategories(obj) %#ok<MANU>
            categoryNames = string.empty(1, 0);
        end

        function categoryNames = validateCategories(~, categoryNames)
            categoryNames = types.util.dynamictable.normalizeColnames(categoryNames);
            validateUniqueCategoryNames(categoryNames)
        end

        function syncNamedCategory(obj, categoryName)
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

            obj.addNameToCategories(categoryName)
        end
    end

    methods (Access = private)
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

        function [tableHeight, hasEstablishedHeight] = getTableHeightInfo(~, dynamicTable)
            matnwb.common.validation.mustBeDynamicTable(dynamicTable);

            if ~isempty(dynamicTable.id)
                [tableHeight, hasEstablishedHeight] = getIdHeightInfo(dynamicTable.id);
                if hasEstablishedHeight
                    return
                end
            end

            if isempty(dynamicTable.colnames)
                tableHeight = 0;
                hasEstablishedHeight = false;
                return
            end

            tableHeight = types.util.dynamictable.internal.getColumnRowHeight( ...
                dynamicTable, dynamicTable.colnames{1});
            tableHeight = unique(tableHeight);

            assert(isscalar(tableHeight), ...
                'NWB:AlignedDynamicTable:GetTableHeightInfo:InvalidShape', ...
                ['Cannot determine DynamicTable row height because one or more ', ...
                'compound column fields have inconsistent heights.']);

            hasEstablishedHeight = true;
        end

        function [parentHeight, parentHasHeight, categoryHeight, categoryHasHeight] = ...
                establishAlignedTableHeight(obj, categoryTable, parentHeight, parentHasHeight)

            [categoryHeight, categoryHasHeight] = obj.getTableHeightInfo(categoryTable);

            if parentHasHeight && ~categoryHasHeight
                obj.initializeTableId(categoryTable, parentHeight);
                categoryHeight = parentHeight;
                categoryHasHeight = true;
            elseif ~parentHasHeight && categoryHasHeight
                obj.initializeTableId(obj, categoryHeight);
                parentHeight = categoryHeight;
                parentHasHeight = true;
            elseif ~parentHasHeight && ~categoryHasHeight
                obj.initializeTableId(categoryTable, 0);
                obj.initializeTableId(obj, 0);
                categoryHeight = 0;
                parentHeight = 0;
                categoryHasHeight = true;
                parentHasHeight = true;
            end
        end

        function initializeTableId(~, dynamicTable, tableHeight)
            matnwb.common.validation.mustBeDynamicTable(dynamicTable);
            validateattributes(tableHeight, {'double'}, ...
                {'scalar', 'integer', 'nonnegative'});

            if isempty(dynamicTable.id)
                types.util.dynamictable.internal.initDynamicTableId(dynamicTable, tableHeight);
                return
            end

            idData = dynamicTable.id.data;
            newIdData = int64(0:tableHeight-1).';

            if isa(idData, 'types.untyped.DataPipe') && ~idData.isBound
                if idData.offset > 0
                    error('NWB:AlignedDynamicTable:CannotInitializeId', ...
                        ['Cannot initialize ids for table `%s` because its id DataPipe ', ...
                        'already has an offset of %d.'], class(dynamicTable), idData.offset)
                end

                if tableHeight > 0
                    idData.append(newIdData)
                end
            elseif isempty(idData)
                dynamicTable.id.data = newIdData;
            else
                error('NWB:AlignedDynamicTable:CannotInitializeId', ...
                    ['Cannot initialize ids for table `%s` because its id dataset ', ...
                    'already has file-backed or non-empty data.'], class(dynamicTable))
            end
        end

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

        function validateMaterializedCategoryTablesAreNotAligned(obj, categoryNames)
            for iCategory = 1:numel(categoryNames)
                categoryTable = obj.getCategoryTable(string(categoryNames{iCategory}));
                obj.validateCategoryTableIsNotAligned(categoryTable);
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

        function addNameToCategories(obj, categoryName)
            categoryNames = obj.validateCategories(obj.categories);
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

        function validateCategoryHeight(categoryName, categoryHeight, parentHeight)
            if categoryHeight ~= parentHeight
                error('NWB:AlignedDynamicTable:AddCategory:MissingRows', ...
                    'Category `%s` has detected height %d, but the parent table height is %d.', ...
                    categoryName, categoryHeight, parentHeight)
            end
        end

        function validateCategoryTableIsNotAligned(categoryTable)
            if isa(categoryTable, 'matnwb.neurodata.AlignedDynamicTableBase')
                error('NWB:AlignedDynamicTable:NestedAlignedTable', ...
                    ['AlignedDynamicTable category tables cannot themselves be ', ...
                    'AlignedDynamicTable instances.'])
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

function [idHeight, hasEstablishedHeight] = getIdHeightInfo(elementIdentifiers)
    idData = elementIdentifiers.data;

    if isa(idData, 'types.untyped.DataStub')
        idHeight = idData.dims(end);
        hasEstablishedHeight = true;
    elseif isa(idData, 'types.untyped.DataPipe')
        [idHeight, hasEstablishedHeight] = getDataPipeHeightInfo(idData);
    elseif isempty(idData)
        idHeight = 0;
        hasEstablishedHeight = false;
    else
        idHeight = types.util.dynamictable.internal.getColumnHeight(elementIdentifiers);
        hasEstablishedHeight = true;
    end
end

function [height, hasEstablishedHeight] = getDataPipeHeightInfo(dataPipe)
    if dataPipe.isBound
        dataSize = size(dataPipe);
        height = dataSize(end);
        hasEstablishedHeight = true;
        return
    end

    if dataPipe.offset > 0
        height = dataPipe.offset;
        hasEstablishedHeight = true;
        return
    end

    height = types.util.dynamictable.internal.getColumnHeight( ...
        types.hdmf_common.ElementIdentifiers('data', dataPipe));
    hasEstablishedHeight = height > 0;
end

function mustNotBeAlignedDynamicTable(value)
    assert(~isa(value, 'matnwb.neurodata.AlignedDynamicTableBase'), ...
        'NWB:AlignedDynamicTable:NestedAlignedTable', ...
        ['Category tables of AlignedDynamicTable cannot themselves be ', ...
        'AlignedDynamicTable instances.'])
end
