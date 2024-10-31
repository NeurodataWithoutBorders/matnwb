function tests = dynamicTableTest()
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    rootPath = fullfile(fileparts(mfilename('fullpath')), '..', '..');
    testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));
    testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
    generateCore('savedir', '.');
    rehash();
end

function setup(testCase) %#ok<INUSD>
    % pass
end

function testNwbToTableWithReferencedTablesAsRowIndices(testCase)
    % The default mode for the toTable() method is to return the row indices
    % for dynamic table regions. This test verifies that the data type of
    % the converted table columns is int64, the default type for indices.
    dtr_table = createDynamicTableWithTableRegionReferences();
    convertedTable = dtr_table.toTable();
    
    testCase.verifyClass(convertedTable.dtr_col_a(1), 'int64')
    testCase.verifyClass(convertedTable.dtr_col_b(1), 'int64')
end

function testNwbToTableWithReferencedTablesAsTableRows(testCase)
    % An alternative mode for the toTable() method is to return the referenced
    % table rows for dynamic table regions as subtables. This test verifies that 
    % the data type of the converted table columns is table.
    dtr_table = createDynamicTableWithTableRegionReferences();
    convertedTable = dtr_table.toTable(false); % Return 
    
    row1colA = convertedTable.dtr_col_a(1);
    row1colB = convertedTable.dtr_col_b(1);
    if iscell(row1colA); row1colA = row1colA{1}; end
    if iscell(row1colB); row1colB = row1colB{1}; end

    testCase.verifyClass(row1colA, 'table')
    testCase.verifyClass(row1colB, 'table')
end

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
