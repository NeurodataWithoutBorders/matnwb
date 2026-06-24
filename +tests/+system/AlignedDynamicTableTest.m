classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...
        AlignedDynamicTableTest < matlab.unittest.TestCase
% AlignedDynamicTableTest - System tests for generated AlignedDynamicTable classes.

    methods (Test)
        function testAddCustomCategoryInitializesParentId(testCase)
            alignedTable = tests.system.AlignedDynamicTableTest.createAlignedTable();
            categoryTable = tests.system.AlignedDynamicTableTest.createTableWithHeight(3);

            alignedTable.addCategory("custom", categoryTable)

            testCase.verifyTrue(alignedTable.dynamictable.isKey("custom"))
            testCase.verifyEqual(alignedTable.categories, {'custom'})
            testCase.verifyEqual(alignedTable.id.data, int64((0:2)'))
        end

        function testAddEmptyTableInitializesParentAndCategoryId(testCase)
            alignedTable = tests.system.AlignedDynamicTableTest.createAlignedTable();
            categoryTable = tests.system.AlignedDynamicTableTest.createEmptyTable();

            testCase.verifyEmpty(alignedTable.id)
            testCase.verifyEmpty(categoryTable.id)

            alignedTable.addCategory("custom", categoryTable)

            testCase.verifyNotEmpty(alignedTable.id)
            testCase.verifyNotEmpty(categoryTable.id)

            testCase.verifyEmpty(alignedTable.id.data)
            testCase.verifyEmpty(categoryTable.id.data)
        end

        function testAddCategoryInitializesEmptyIdDataPipe(testCase)
            parent = types.hdmf_common.AlignedDynamicTable( ...
                'description', 'parent', ...
                'id', types.hdmf_common.ElementIdentifiers('data', int64((0:9)')));
        
            idDataPipe = types.untyped.DataPipe( ...
                'maxSize', Inf, ...
                'dataType', 'int64');
        
            category = types.hdmf_common.DynamicTable( ...
                'description', 'category');
            category.id = types.hdmf_common.ElementIdentifiers('data', idDataPipe);
        
            parent.addCategory("category", category)
        
            testCase.verifyEqual(idDataPipe.internal.data, int64((0:9)'))
            types.util.dynamictable.checkConfig(category)
        end

        function testGetCustomCategory(testCase)
            alignedTable = tests.system.AlignedDynamicTableTest.createAlignedTable();
            categoryTable = tests.system.AlignedDynamicTableTest.createTableWithHeight(3);

            alignedTable.addCategory("custom", categoryTable)

            testCase.verifyTrue(alignedTable.getCategory("custom") == categoryTable)
        end

        function testAddCustomCategoryRejectsExistingCategory(testCase)
            alignedTable = tests.system.AlignedDynamicTableTest.createAlignedTable();
            categoryTable = tests.system.AlignedDynamicTableTest.createTableWithHeight(2);
            replacementTable = tests.system.AlignedDynamicTableTest.createTableWithHeight(2);
            alignedTable.addCategory("custom", categoryTable)

            testCase.verifyError( ...
                @() alignedTable.addCategory("custom", replacementTable), ...
                'NWB:AlignedDynamicTable:AddCategory:CategoryExists')
        end

        function testAddCategoryInitializesEmptyCategoryId(testCase)
            alignedTable = tests.system.AlignedDynamicTableTest.createAlignedTableWithId( ...
                int64((0:2)'));
            categoryTable = tests.system.AlignedDynamicTableTest.createEmptyTable();

            alignedTable.addCategory("custom", categoryTable)

            testCase.verifyEqual(categoryTable.id.data, int64((0:2)'))
        end

        function testAddCategoryRejectsHeightMismatch(testCase)
            alignedTable = tests.system.AlignedDynamicTableTest.createAlignedTableWithId( ...
                int64((0:2)'));
            categoryTable = tests.system.AlignedDynamicTableTest.createTableWithHeight(2);

            testCase.verifyError( ...
                @() alignedTable.addCategory("custom", categoryTable), ...
                'NWB:AlignedDynamicTable:AddCategory:MissingRows')
        end

        function testAddCategoryRejectsNestedAlignedTable(testCase)
            alignedTable = tests.system.AlignedDynamicTableTest.createAlignedTable();
            nestedTable = tests.system.AlignedDynamicTableTest.createAlignedTable();

            testCase.verifyError( ...
                @() alignedTable.addCategory("nested", nestedTable), ...
                'NWB:AlignedDynamicTable:NestedAlignedTable')
        end

        function testAddSchemaCategoryUsesNamedProperty(testCase)
            alignedTable = tests.system.AlignedDynamicTableTest.createSchemaAlignedTable();
            categoryTable = tests.system.AlignedDynamicTableTest.createElectrodesTableWithHeight(2);

            alignedTable.addCategory("electrodes", categoryTable)

            testCase.verifyTrue(alignedTable.electrodes == categoryTable)
            testCase.verifyFalse(alignedTable.dynamictable.isKey("electrodes"))
            testCase.verifyEqual(alignedTable.categories, {'electrodes'})
        end

        function testGetSchemaCategory(testCase)
            alignedTable = tests.system.AlignedDynamicTableTest.createSchemaAlignedTable();
            categoryTable = tests.system.AlignedDynamicTableTest.createElectrodesTableWithHeight(2);

            alignedTable.addCategory("electrodes", categoryTable)

            testCase.verifyTrue(alignedTable.getCategory("electrodes") == categoryTable)
        end

        function testAddSchemaCategoryRejectsExistingCategory(testCase)
            alignedTable = tests.system.AlignedDynamicTableTest.createSchemaAlignedTable();
            categoryTable = tests.system.AlignedDynamicTableTest.createElectrodesTableWithHeight(2);
            replacementTable = tests.system.AlignedDynamicTableTest.createElectrodesTableWithHeight(2);
            alignedTable.addCategory("electrodes", categoryTable)

            testCase.verifyError( ...
                @() alignedTable.addCategory("electrodes", replacementTable), ...
                'NWB:AlignedDynamicTable:AddCategory:CategoryExists')
        end

        function testGetCategoryRejectsMissingCategory(testCase)
            alignedTable = tests.system.AlignedDynamicTableTest.createSchemaAlignedTableWithCategories( ...
                {'electrodes'});

            testCase.verifyError( ...
                @() alignedTable.getCategory("electrodes"), ...
                'NWB:AlignedDynamicTable:CategoryNotFound')
        end


        function testGetCategoryRejectsMissingCustomCategory(testCase)
            alignedTable = tests.system.AlignedDynamicTableTest.createSchemaAlignedTable();

            testCase.verifyError( ...
                @() alignedTable.getCategory("nonExistingCategory"), ...
                'NWB:AlignedDynamicTable:CategoryNotFound')
        end

        function testMissingCategoryNameThrows(testCase)
            alignedTable = tests.system.AlignedDynamicTableTest.createAlignedTable();
            categoryTable = tests.factory.DynamicTable('NumColumns', 1, 'NumRows', 1);

            % Add category (bypassing category registration)
            alignedTable.dynamictable.set('category', categoryTable);

            testCase.verifyError(...
                @alignedTable.ensureAlignedTableConsistency, ...
                'NWB:AlignedDynamicTable:ValidateAlignedTableConsistency:CategoryNamesMismatch' ...
                )
        end

        function testDirectSchemaCategoryAssignmentSyncsCategories(testCase)
            alignedTable = tests.system.AlignedDynamicTableTest.createSchemaAlignedTable();
            categoryTable = tests.system.AlignedDynamicTableTest.createElectrodesTableWithHeight(2);

            alignedTable.electrodes = categoryTable;

            testCase.verifyEqual(alignedTable.categories, {'electrodes'})
        end

        function testAddDuplicateCategoryNameFails(testCase)
            alignedTable = tests.system.AlignedDynamicTableTest.createAlignedTable();
            categoryTable = tests.system.AlignedDynamicTableTest.createTableWithHeight(1);

            alignedTable.addCategory("custom", categoryTable)

            testCase.verifyError(...
                @() assignCategoryNameToCategories(alignedTable, 'custom'), ...
                'NWB:AlignedDynamicTable:DuplicateCategoryNames')

            function assignCategoryNameToCategories(alignedTable, name)
                alignedTable.categories{end+1} = name;
            end
        end

        function testConstructorAllowsSchemaCategoriesBeforeTables(testCase)
            alignedTable = tests.system.AlignedDynamicTableTest.createSchemaAlignedTableWithCategories( ...
                {'electrodes'});

            testCase.verifyEqual(alignedTable.categories, {'electrodes'})
            testCase.verifyEmpty(alignedTable.electrodes)

            categoryTable = tests.system.AlignedDynamicTableTest.createElectrodesTableWithHeight(2);
            alignedTable.addCategory("electrodes", categoryTable)

            testCase.verifyTrue(alignedTable.electrodes == categoryTable)
            testCase.verifyEqual(alignedTable.categories, {'electrodes'})
        end

        function testDeclaredMissingCategoryFailsWhenHeightExists(testCase)
            testCase.verifyError( ...
                @() tests.system.AlignedDynamicTableTest.createSchemaAlignedTable( ...
                    Categories={'electrodes'}, ...
                    IdData=int64((0:1)')), ...
                'NWB:AlignedDynamicTable:ValidateAlignedTableConsistency:CategoryNamesMismatch')
        end

        function testValidateAlignedTableConsistencyDetectsUnregisteredCategory(testCase)
            alignedTable = tests.system.AlignedDynamicTableTest.createAlignedTable();
            categoryTable = tests.system.AlignedDynamicTableTest.createTableWithHeight(2);
            alignedTable.dynamictable.set("custom", categoryTable);

            testCase.verifyError( ...
                @() alignedTable.ensureAlignedTableConsistency(), ...
                'NWB:AlignedDynamicTable:ValidateAlignedTableConsistency:CategoryNamesMismatch')
        end

        function testValidateAlignedTableConsistencyRejectsNestedAlignedTable(testCase)
            alignedTable = tests.system.AlignedDynamicTableTest.createAlignedTableWithCategories( ...
                {'nested'});
            nestedTable = tests.system.AlignedDynamicTableTest.createAlignedTable();
            alignedTable.dynamictable.set("nested", nestedTable);

            testCase.verifyError( ...
                @() alignedTable.ensureAlignedTableConsistency(), ...
                'NWB:AlignedDynamicTable:NestedAlignedTable')
        end

        function testValidateAlignedTableConsistencyRejectsUnlistedNestedTable(testCase)
            alignedTable = tests.system.AlignedDynamicTableTest.createAlignedTable();
            nestedTable = tests.system.AlignedDynamicTableTest.createAlignedTable();
            alignedTable.dynamictable.set("nested", nestedTable);

            testCase.verifyError( ...
                @() alignedTable.ensureAlignedTableConsistency(), ...
                'NWB:AlignedDynamicTable:NestedAlignedTable')
        end

        function testUnboundDataPipeIdHeightIsOffset(testCase)
            idDataPipe = types.untyped.DataPipe( ...
                'maxSize', Inf, ...
                'axis', 1, ...
                'offset', 3, ...
                'dataType', 'int64');
            alignedTable = tests.system.AlignedDynamicTableTest.createAlignedTableWithId(idDataPipe);
            categoryTable = tests.system.AlignedDynamicTableTest.createTableWithHeight(3);

            alignedTable.addCategory("custom", categoryTable)

            testCase.verifyEqual(alignedTable.categories, {'custom'})
        end
    end

    methods (Static, Access = private)
        function alignedTable = createAlignedTable()
            alignedTable = types.hdmf_common.AlignedDynamicTable( ...
                'description', 'parent table');
        end

        function alignedTable = createAlignedTableWithId(idData)
            alignedTable = types.hdmf_common.AlignedDynamicTable( ...
                'description', 'parent table', ...
                'id', tests.system.AlignedDynamicTableTest.createId(idData));
        end

        function alignedTable = createAlignedTableWithCategories(categories)
            alignedTable = types.hdmf_common.AlignedDynamicTable( ...
                'description', 'parent table', ...
                'categories', categories);
        end

        function alignedTable = createSchemaAlignedTable(options)
            arguments
                options.Categories = []
                options.IdData = []
            end

            constructorArguments = {};
            if ~isempty(options.Categories)
                constructorArguments = [constructorArguments, {'categories', options.Categories}];
            end
            if ~isempty(options.IdData)
                constructorArguments = [constructorArguments, { ...
                    'id', tests.system.AlignedDynamicTableTest.createId(options.IdData)}];
            end

            alignedTable = types.core.IntracellularRecordingsTable(constructorArguments{:});
        end

        function alignedTable = createSchemaAlignedTableWithCategories(categories)
            alignedTable = tests.system.AlignedDynamicTableTest.createSchemaAlignedTable( ...
                Categories=categories);
        end

        function dynamicTable = createEmptyTable()
            dynamicTable = types.hdmf_common.DynamicTable( ...
                'description', 'category table');
        end

        function dynamicTable = createTableWithHeight(tableHeight)
            dynamicTable = types.hdmf_common.DynamicTable( ...
                'description', 'category table', ...
                'id', tests.system.AlignedDynamicTableTest.createId(int64((0:tableHeight-1)')));
        end

        function dynamicTable = createElectrodesTableWithHeight(tableHeight)
            dynamicTable = types.core.IntracellularElectrodesTable( ...
                'id', tests.system.AlignedDynamicTableTest.createId(int64((0:tableHeight-1)')));
        end

        function id = createId(idData)
            id = types.hdmf_common.ElementIdentifiers('data', idData);
        end
    end
end
