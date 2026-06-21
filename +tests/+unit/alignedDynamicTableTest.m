classdef alignedDynamicTableTest < matlab.unittest.TestCase
    %alignedDynamicTableTest Tests for AlignedDynamicTable category utilities.

    methods (Test)
        function testAddCustomCategoryInitializesParentId(testCase)
            alignedTable = types.hdmf_common.AlignedDynamicTable( ...
                'description', 'parent table');
            categoryTable = tests.unit.alignedDynamicTableTest.createTableWithHeight(3);

            alignedTable.addCategory("custom", categoryTable)

            testCase.verifyTrue(alignedTable.dynamictable.isKey("custom"))
            testCase.verifyEqual(alignedTable.categories, {'custom'})
            testCase.verifyEqual(alignedTable.id.data, int64((0:2)'))
        end

        function testAddCategoryInitializesEmptyCategoryId(testCase)
            alignedTable = types.hdmf_common.AlignedDynamicTable( ...
                'description', 'parent table', ...
                'id', types.hdmf_common.ElementIdentifiers('data', int64((0:2)')));
            categoryTable = types.hdmf_common.DynamicTable( ...
                'description', 'empty category table');

            alignedTable.addCategory("custom", categoryTable)

            testCase.verifyEqual(categoryTable.id.data, int64((0:2)'))
        end

        function testAddCategoryRejectsHeightMismatch(testCase)
            alignedTable = types.hdmf_common.AlignedDynamicTable( ...
                'description', 'parent table', ...
                'id', types.hdmf_common.ElementIdentifiers('data', int64((0:2)')));
            categoryTable = tests.unit.alignedDynamicTableTest.createTableWithHeight(2);

            testCase.verifyError( ...
                @() alignedTable.addCategory("custom", categoryTable), ...
                'NWB:AlignedDynamicTable:AddCategory:MissingRows')
        end

        function testAddSchemaCategoryUsesNamedProperty(testCase)
            alignedTable = tests.doubles.SchemaCategoryAlignedTable( ...
                'description', 'parent table');
            categoryTable = tests.unit.alignedDynamicTableTest.createTableWithHeight(2);

            alignedTable.addCategory("categoryOne", categoryTable)

            testCase.verifyTrue(alignedTable.categoryOne == categoryTable)
            testCase.verifyFalse(alignedTable.dynamictable.isKey("categoryOne"))
            testCase.verifyEqual(alignedTable.categories, {'categoryOne'})
        end

        function testDirectSchemaCategoryAssignmentSyncsCategories(testCase)
            alignedTable = tests.doubles.SchemaCategoryAlignedTable( ...
                'description', 'parent table');
            categoryTable = tests.unit.alignedDynamicTableTest.createTableWithHeight(2);

            alignedTable.categoryOne = categoryTable;

            testCase.verifyEqual(alignedTable.categories, {'categoryOne'})
        end

        function testConstructorAllowsSchemaCategoriesBeforeTables(testCase)
            alignedTable = tests.doubles.SchemaCategoryAlignedTable( ...
                'description', 'parent table', ...
                'categories', {'categoryOne'});

            testCase.verifyEqual(alignedTable.categories, {'categoryOne'})
            testCase.verifyEmpty(alignedTable.categoryOne)

            categoryTable = types.hdmf_common.DynamicTable( ...
                'description', 'category table', ...
                'id', types.hdmf_common.ElementIdentifiers('data', int64((0:1)')));
            alignedTable.addCategory("categoryOne", categoryTable)

            testCase.verifyTrue(alignedTable.categoryOne == categoryTable)
            testCase.verifyEqual(alignedTable.categories, {'categoryOne'})
        end

        function testDeclaredMissingCategoryFailsWhenHeightExists(testCase)
            testCase.verifyError( ...
                @() tests.doubles.SchemaCategoryAlignedTable( ...
                    'description', 'parent table', ...
                    'categories', {'categoryOne'}, ...
                    'id', types.hdmf_common.ElementIdentifiers( ...
                        'data', int64((0:1)'))), ...
                'NWB:AlignedDynamicTable:CheckConfig:CategoryNamesMismatch')
        end

        function testCheckConfigDetectsUnregisteredCategory(testCase)
            alignedTable = types.hdmf_common.AlignedDynamicTable( ...
                'description', 'parent table');
            categoryTable = tests.unit.alignedDynamicTableTest.createTableWithHeight(2);
            alignedTable.dynamictable.set("custom", categoryTable);

            testCase.verifyError( ...
                @() types.util.aligneddynamictable.checkConfig(alignedTable), ...
                'NWB:AlignedDynamicTable:CheckConfig:CategoryNamesMismatch')
        end

        function testUnboundDataPipeIdHeightIsOffset(testCase)
            idDataPipe = types.untyped.DataPipe( ...
                'maxSize', Inf, ...
                'axis', 1, ...
                'offset', 3, ...
                'dataType', 'int64');
            alignedTable = types.hdmf_common.AlignedDynamicTable( ...
                'description', 'parent table', ...
                'id', types.hdmf_common.ElementIdentifiers('data', idDataPipe));
            categoryTable = tests.unit.alignedDynamicTableTest.createTableWithHeight(3);

            alignedTable.addCategory("custom", categoryTable)

            testCase.verifyEqual(alignedTable.categories, {'custom'})
        end
    end

    methods (Static, Access = private)
        function dynamicTable = createTableWithHeight(tableHeight)
            dynamicTable = types.hdmf_common.DynamicTable( ...
                'description', 'category table', ...
                'id', types.hdmf_common.ElementIdentifiers( ...
                    'data', int64((0:tableHeight-1)')));
        end
    end
end
