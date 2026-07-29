classdef DynamicTableColumnTest < tests.unit.abstract.SchemaTest
% DynamicTableColumnTest - Test schema-defined DynamicTable column detection.

    properties (Constant)
        SchemaFolder = "dynamicTableColumnSchema"
        SchemaNamespaceFileName = "dtc.namespace.yaml"
    end

    methods (Test)
        function testVectorDataDatasetUsesGeneratedProperty(testCase)
            dynamicTable = types.dtc.MixedDatasetTable( ...
                'description', 'test table');
            schemaColumn = types.hdmf_common.VectorData( ...
                'description', 'schema column', ...
                'data', single((1:3)'));

            dynamicTable.addColumn('schema_column', schemaColumn);

            testCase.verifyEqual(dynamicTable.schema_column, schemaColumn)
            testCase.verifyFalse( ...
                dynamicTable.vectordata.isKey('schema_column'))
        end

        function testNonColumnDatasetRemainsPropertyCollision(testCase)
            dynamicTable = types.dtc.MixedDatasetTable( ...
                'description', 'test table');
            invalidColumn = types.hdmf_common.VectorData( ...
                'description', 'invalid column', ...
                'data', single((1:3)'));

            testCase.verifyError( ...
                @() dynamicTable.addColumn( ...
                    'table_metadata', invalidColumn), ...
                'NWB:DynamicTable:AddColumn:InvalidPropertyCollision')
        end
    end
end
