classdef alignedDynamicTableTest < matlab.unittest.TestCase
    %alignedDynamicTableTest Tests for AlignedDynamicTable category utilities.

    methods (Test)
        function testAddCustomCategoryInitializesParentId(testCase)
            alignedTable = tests.doubles.AlignedDynamicTableStub( ...
                Description='parent table');
            categoryTable = tests.unit.alignedDynamicTableTest.createTableWithHeight(3);

            alignedTable.addCategory("custom", categoryTable)

            testCase.verifyTrue(alignedTable.dynamictable.isKey("custom"))
            testCase.verifyEqual(alignedTable.categories, {'custom'})
            testCase.verifyEqual(alignedTable.id.data, int64((0:2)'))
        end

        function testGetCustomCategory(testCase)
            alignedTable = tests.doubles.AlignedDynamicTableStub( ...
                Description='parent table');
            categoryTable = tests.unit.alignedDynamicTableTest.createTableWithHeight(3);

            alignedTable.addCategory("custom", categoryTable)

            testCase.verifyTrue(alignedTable.getCategory("custom") == categoryTable)
        end

        function testAddCustomCategoryRejectsExistingCategory(testCase)
            alignedTable = tests.doubles.AlignedDynamicTableStub( ...
                Description='parent table');
            categoryTable = tests.unit.alignedDynamicTableTest.createTableWithHeight(2);
            replacementTable = tests.unit.alignedDynamicTableTest.createTableWithHeight(2);
            alignedTable.addCategory("custom", categoryTable)

            testCase.verifyError( ...
                @() alignedTable.addCategory("custom", replacementTable), ...
                'NWB:AlignedDynamicTable:AddCategory:CategoryExists')
        end

        function testAddCategoryInitializesEmptyCategoryId(testCase)
            alignedTable = tests.doubles.AlignedDynamicTableStub( ...
                Description='parent table', ...
                IdData=int64((0:2)'));
            categoryTable = tests.doubles.DynamicTableStub( ...
                Description='empty category table');

            alignedTable.addCategory("custom", categoryTable)

            testCase.verifyEqual(categoryTable.id.data, int64((0:2)'))
        end

        function testAddCategoryRejectsHeightMismatch(testCase)
            alignedTable = tests.doubles.AlignedDynamicTableStub( ...
                Description='parent table', ...
                IdData=int64((0:2)'));
            categoryTable = tests.unit.alignedDynamicTableTest.createTableWithHeight(2);

            testCase.verifyError( ...
                @() alignedTable.addCategory("custom", categoryTable), ...
                'NWB:AlignedDynamicTable:AddCategory:MissingRows')
        end

        function testAddCategoryRejectsNestedAlignedTable(testCase)
            alignedTable = tests.doubles.AlignedDynamicTableStub( ...
                Description='parent table');
            nestedTable = tests.doubles.SchemaCategoryAlignedTable( ...
                Description='nested aligned table');

            testCase.verifyError( ...
                @() alignedTable.addCategory("nested", nestedTable), ...
                'NWB:AlignedDynamicTable:NestedAlignedTable')
        end

        function testAddSchemaCategoryUsesNamedProperty(testCase)
            alignedTable = tests.doubles.SchemaCategoryAlignedTable( ...
                Description='parent table');
            categoryTable = tests.unit.alignedDynamicTableTest.createTableWithHeight(2);

            alignedTable.addCategory("categoryOne", categoryTable)

            testCase.verifyTrue(alignedTable.categoryOne == categoryTable)
            testCase.verifyFalse(alignedTable.dynamictable.isKey("categoryOne"))
            testCase.verifyEqual(alignedTable.categories, {'categoryOne'})
        end

        function testGetSchemaCategory(testCase)
            alignedTable = tests.doubles.SchemaCategoryAlignedTable( ...
                Description='parent table');
            categoryTable = tests.unit.alignedDynamicTableTest.createTableWithHeight(2);

            alignedTable.addCategory("categoryOne", categoryTable)

            testCase.verifyTrue(alignedTable.getCategory("categoryOne") == categoryTable)
        end

        function testAddSchemaCategoryRejectsExistingCategory(testCase)
            alignedTable = tests.doubles.SchemaCategoryAlignedTable( ...
                Description='parent table');
            categoryTable = tests.unit.alignedDynamicTableTest.createTableWithHeight(2);
            replacementTable = tests.unit.alignedDynamicTableTest.createTableWithHeight(2);
            alignedTable.addCategory("categoryOne", categoryTable)

            testCase.verifyError( ...
                @() alignedTable.addCategory("categoryOne", replacementTable), ...
                'NWB:AlignedDynamicTable:AddCategory:CategoryExists')
        end

        function testGetCategoryRejectsMissingCategory(testCase)
            alignedTable = tests.doubles.SchemaCategoryAlignedTable( ...
                Description='parent table', ...
                Categories={'categoryOne'});

            testCase.verifyError( ...
                @() alignedTable.getCategory("categoryOne"), ...
                'NWB:AlignedDynamicTable:CategoryNotFound')
        end

        function testDirectSchemaCategoryAssignmentSyncsCategories(testCase)
            alignedTable = tests.doubles.SchemaCategoryAlignedTable( ...
                Description='parent table');
            categoryTable = tests.unit.alignedDynamicTableTest.createTableWithHeight(2);

            alignedTable.categoryOne = categoryTable;

            testCase.verifyEqual(alignedTable.categories, {'categoryOne'})
        end

        function testConstructorAllowsSchemaCategoriesBeforeTables(testCase)
            alignedTable = tests.doubles.SchemaCategoryAlignedTable( ...
                Description='parent table', ...
                Categories={'categoryOne'});

            testCase.verifyEqual(alignedTable.categories, {'categoryOne'})
            testCase.verifyEmpty(alignedTable.categoryOne)

            categoryTable = tests.doubles.DynamicTableStub( ...
                Description='category table', ...
                IdData=int64((0:1)'));
            alignedTable.addCategory("categoryOne", categoryTable)

            testCase.verifyTrue(alignedTable.categoryOne == categoryTable)
            testCase.verifyEqual(alignedTable.categories, {'categoryOne'})
        end

        function testDeclaredMissingCategoryFailsWhenHeightExists(testCase)
            testCase.verifyError( ...
                @() tests.doubles.SchemaCategoryAlignedTable( ...
                    Description='parent table', ...
                    Categories={'categoryOne'}, ...
                    IdData=int64((0:1)')), ...
                'NWB:AlignedDynamicTable:ValidateAlignedTableConsistency:CategoryNamesMismatch')
        end

        function testValidateAlignedTableConsistencyDetectsUnregisteredCategory(testCase)
            alignedTable = tests.doubles.AlignedDynamicTableStub( ...
                Description='parent table');
            categoryTable = tests.unit.alignedDynamicTableTest.createTableWithHeight(2);
            alignedTable.dynamictable.set("custom", categoryTable);

            testCase.verifyError( ...
                @() alignedTable.ensureAlignedTableConsistency(), ...
                'NWB:AlignedDynamicTable:ValidateAlignedTableConsistency:CategoryNamesMismatch')
        end

        function testValidateAlignedTableConsistencyRejectsNestedAlignedTable(testCase)
            alignedTable = tests.doubles.AlignedDynamicTableStub( ...
                Description='parent table', ...
                Categories={'nested'});
            nestedTable = tests.doubles.SchemaCategoryAlignedTable( ...
                Description='nested aligned table');
            alignedTable.dynamictable.set("nested", nestedTable);

            testCase.verifyError( ...
                @() alignedTable.ensureAlignedTableConsistency(), ...
                'NWB:AlignedDynamicTable:NestedAlignedTable')
        end

        function testValidateAlignedTableConsistencyRejectsUnlistedNestedTable(testCase)
            alignedTable = tests.doubles.AlignedDynamicTableStub( ...
                Description='parent table');
            nestedTable = tests.doubles.SchemaCategoryAlignedTable( ...
                Description='nested aligned table');
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
            alignedTable = tests.doubles.AlignedDynamicTableStub( ...
                Description='parent table', ...
                IdData=idDataPipe);
            categoryTable = tests.unit.alignedDynamicTableTest.createTableWithHeight(3);

            alignedTable.addCategory("custom", categoryTable)

            testCase.verifyEqual(alignedTable.categories, {'custom'})
        end
    end

    methods (Static, Access = private)
        function dynamicTable = createTableWithHeight(tableHeight)
            dynamicTable = tests.doubles.DynamicTableStub( ...
                Description='category table', ...
                IdData=int64((0:tableHeight-1)'));
        end
    end
end
