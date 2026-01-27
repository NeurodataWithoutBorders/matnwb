classdef dynamicTableTest < tests.abstract.NwbTestCase

    methods (TestClassSetup)
        function setupClass(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end
    
    methods (Test)
        function testNwbToTableWithReferencedTablesAsRowIndices(testCase)
            % The default mode for the toTable() method is to return the row indices
            % for dynamic table regions. This test verifies that the data type of
            % the converted table columns is int64, the default type for indices.
            dtr_table = testCase.createDynamicTableWithTableRegionReferences();
            convertedTable = dtr_table.toTable();
            
            testCase.verifyClass(convertedTable.dtr_col_a(1), 'int64')
            testCase.verifyClass(convertedTable.dtr_col_b(1), 'int64')
        end
        
        function testNwbToTableWithReferencedTablesAsTableRows(testCase)
            % An alternative mode for the toTable() method is to return the referenced
            % table rows for dynamic table regions as subtables. This test verifies that 
            % the data type of the converted table columns is table.
            dtr_table = testCase.createDynamicTableWithTableRegionReferences();
            convertedTable = dtr_table.toTable(false); % Return 
            
            row1colA = convertedTable.dtr_col_a(1);
            row1colB = convertedTable.dtr_col_b(1);
            if iscell(row1colA); row1colA = row1colA{1}; end
            if iscell(row1colB); row1colB = row1colB{1}; end
        
            testCase.verifyClass(row1colA, 'table')
            testCase.verifyClass(row1colB, 'table')
        end
        
        function testClearDynamicTable(testCase)
            dtr_table = testCase.createDynamicTableWithTableRegionReferences();
            types.util.dynamictable.clear(dtr_table)
        
            % testCase.verifyEmpty(dtr_table.vectordata) %todo when PR merged
            testCase.verifyEqual(size(dtr_table.vectordata), uint64([0,1]))
        end
        
        function testClearDynamicTableV2_1(testCase)
        
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            testCase.applyFixture(...
                SuppressedWarningsFixture('NWB:CheckUnset:InvalidProperties'))
            
            typesOutputFolder = testCase.getTypesOutputFolder();

            nwbClearGenerated(typesOutputFolder, 'ClearCache', true)
            generateCore("2.1.0", "savedir", typesOutputFolder)

            table = types.core.DynamicTable( ...
                'description', 'test table with DynamicTableRegion', ...
                'colnames', {'dtr_col_a', 'dtr_col_b'}, ...
                'dtr_col_a', 1:4, ...
                'dtr_col_b', 5:8, ...
                'id', types.core.ElementIdentifiers('data', [0; 1; 2; 3]) );
        
            types.util.dynamictable.clear(table)
        
            testCase.verifyEqual(size(table.vectordata), uint64([0,1]))
        
            nwbClearGenerated(typesOutputFolder, 'ClearCache',true)
            generateCore('savedir', typesOutputFolder);
        end
        
        function testToTableForNdVectorData(testCase)
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            testCase.applyFixture(...
                SuppressedWarningsFixture('NWB:DynamicTable:VectorDataAmbiguousSize'))
            
            arrayLength = 5;
            numTableRows = 3;
            nDimsToTest = [2,3,4];
        
            for nDims = nDimsToTest
                vectorDataShape = repmat(arrayLength, 1, nDims-1);
        
                dynamicTable = types.hdmf_common.DynamicTable( ...
                    'description', 'test table with n-dimensional VectorData', ...
                    'colnames', {'columnA', 'columnB'}, ...
                    'columnA', types.hdmf_common.VectorData('data', randi(10, [vectorDataShape, numTableRows])), ...
                    'columnB', types.hdmf_common.VectorData('data', randi(10, [vectorDataShape, numTableRows])), ...
                    'id', types.hdmf_common.ElementIdentifiers('data', (0:numTableRows-1)'  ) );
                
                T = dynamicTable.toTable();
                testCase.verifyClass(T, 'table');
                testCase.verifySize(T.columnA, [numTableRows, vectorDataShape])
            end
        end
        
        function testToTableForTableImportedFromFile(testCase)
            fileName = testCase.getRandomFilename();
        
            nwb = tests.factory.NWBFile();
            
            dynamicTable = testCase.createDynamicTable();
            nwb.acquisition.set('DynamicTable', dynamicTable);

            nwbExport(nwb, fileName)
        
            nwbIn = nwbRead(fileName, "ignorecache");
        
            T = nwbIn.acquisition.get('DynamicTable').toTable();
            testCase.verifyClass(T, 'table')
        end

        function testAddColumnToEmptyTableInitializesId(testCase)
            % Test that adding the first column to an empty table 
            % automatically initializes the id column with 0-indexed values
            numRows = 5;
            
            dynamicTable = types.hdmf_common.DynamicTable( ...
                'description', 'empty test table');
            
            columnA = types.hdmf_common.VectorData(...
                'description', 'first column', ...
                'data', (1:numRows)');
            
            dynamicTable.addColumn('columnA', columnA);
            
            % Verify id was created with correct values
            testCase.verifyNotEmpty(dynamicTable.id);
            testCase.verifyNotEmpty(dynamicTable.id.data);
            testCase.verifyEqual(dynamicTable.id.data, int64((0:numRows-1)'));
            
            % Verify the column was added
            testCase.verifyEqual(dynamicTable.colnames, {'columnA'});
            testCase.verifyTrue(dynamicTable.vectordata.isKey('columnA'));
        end

        function testAddColumnToEmptyTableWithRaggedColumnInitializesId(testCase)
            % Test that adding the first ragged column to an empty table 
            % automatically initializes the id column based on index length
            numRows = 4;
            
            dynamicTable = types.hdmf_common.DynamicTable( ...
                'description', 'empty test table');
            
            % Create ragged column data
            raggedData = {[1,2,3], [4,5], [6,7,8,9], [10]};
            [vectorData, vectorIndex] = util.create_indexed_column(raggedData);
            
            dynamicTable.addColumn('raggedCol', vectorData, 'raggedCol_index', vectorIndex);
            
            % Verify id was created with correct values based on index length
            testCase.verifyNotEmpty(dynamicTable.id);
            testCase.verifyNotEmpty(dynamicTable.id.data);
            testCase.verifyEqual(dynamicTable.id.data, int64((0:numRows-1)'));
        end

        function testAddColumnThrowsErrorForExistingColumn(testCase)
            % Test that adding a column that already exists throws an error
            dynamicTable = testCase.createDynamicTable();
            
            % Try to add a column with an existing name
            duplicateColumn = types.hdmf_common.VectorData(...
                'description', 'duplicate column', ...
                'data', (1:10)');
            
            testCase.verifyError(...
                @() dynamicTable.addColumn('columnA', duplicateColumn), ...
                'NWB:DynamicTable:AddColumn:ColumnExists');
        end

        function testAddMultipleColumnsThrowsErrorIfAnyExists(testCase)
            % Test that adding multiple columns throws an error if any column already exists
            dynamicTable = testCase.createDynamicTable();
            
            newColumn = types.hdmf_common.VectorData(...
                'description', 'new column', ...
                'data', (1:10)');
            duplicateColumn = types.hdmf_common.VectorData(...
                'description', 'duplicate column', ...
                'data', (1:10)');
            
            testCase.verifyError(...
                @() dynamicTable.addColumn('newColumn', newColumn, 'columnA', duplicateColumn), ...
                'NWB:DynamicTable:AddColumn:ColumnExists');
        end
    end

    methods (Static, Access=private)
        
        % Non-test functions
        function dtr_table = createDynamicTableWithTableRegionReferences()
            % Create a dynamic table with two columns, where the data of each column is 
            % a dynamic table region referencing another dynamic table.
            T = table([1;2;3], {'a';'b';'c'}, 'VariableNames', {'col1', 'col2'});
            T.Properties.VariableDescriptions = {'column #1', 'column #2'};
            
            T = util.table2nwb(T);
            
            dtr_col_a = types.hdmf_common.DynamicTableRegion( ...
                'description', 'references multiple rows of earlier table', ...
                'data', [0; 1; 1; 0], ...  # 0-indexed
                'table',types.untyped.ObjectView(T) ...  % object view of target table
            );
            
            dtr_col_b = types.hdmf_common.DynamicTableRegion( ...
                'description', 'references multiple rows of earlier table', ...
                'data', [1; 2; 2; 1], ...  # 0-indexed
                'table',types.untyped.ObjectView(T) ...  % object view of target table
            );
            
            dtr_table = types.hdmf_common.DynamicTable( ...
                'description', 'test table with DynamicTableRegion', ...
                'colnames', {'dtr_col_a', 'dtr_col_b'}, ...
                'dtr_col_a', dtr_col_a, ...
                'dtr_col_b', dtr_col_b, ...
                'id',types.hdmf_common.ElementIdentifiers('data', [0; 1; 2; 3]) ...
            );
        end

        function dynamicTable = createDynamicTable()
            numTableRows = 10;
            
            columnA = types.hdmf_common.VectorData(...
                'description', 'first_column', ...
                'data', randi(10, [1, numTableRows]));
            columnB = types.hdmf_common.VectorData(...
                'description', 'second_column', ...
                'data', randi(10, [1, numTableRows]));
            idColumn = types.hdmf_common.ElementIdentifiers(...
                'data', (0:numTableRows-1)' );

            dynamicTable = types.hdmf_common.DynamicTable( ...
                'description', 'test table with n-dimensional VectorData', ...
                'colnames', {'columnA', 'columnB'}, ...
                'columnA', columnA, ...
                'columnB', columnB, ...
                'id', idColumn);
        end
    end
end
