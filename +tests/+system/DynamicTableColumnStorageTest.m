classdef DynamicTableColumnStorageTest < matlab.unittest.TestCase
% DynamicTableColumnStorageTest - Test generated DynamicTable column routing.

    methods (Test)
        function testSchemaDataColumnUsesGeneratedProperty(testCase)
            timeIntervals = types.core.TimeIntervals( ...
                'description', 'test time intervals');
            startTime = types.hdmf_common.VectorData( ...
                'description', 'start time', ...
                'data', single((1:3)'));

            timeIntervals.addColumn('start_time', startTime);

            testCase.verifyEqual(timeIntervals.start_time, startTime)
            testCase.verifyFalse(timeIntervals.vectordata.isKey('start_time'))
            testCase.verifyEqual(timeIntervals.colnames, {'start_time'})
        end

        function testSchemaIndexColumnUsesGeneratedProperty(testCase)
            timeIntervals = types.core.TimeIntervals( ...
                'description', 'test time intervals');
            tags = types.hdmf_common.VectorData( ...
                'description', 'tags', ...
                'data', {'a'; 'b'; 'c'});
            tagsIndex = types.hdmf_common.VectorIndex( ...
                'description', 'tag indices', ...
                'data', uint64([2; 3]), ...
                'target', types.untyped.ObjectView(tags));

            timeIntervals.addColumn( ...
                'tags', tags, ...
                'tags_index', tagsIndex);

            testCase.verifyEqual(timeIntervals.tags, tags)
            testCase.verifyEqual(timeIntervals.tags_index, tagsIndex)
            testCase.verifyFalse(timeIntervals.vectordata.isKey('tags'))
            testCase.verifyFalse(timeIntervals.vectordata.isKey('tags_index'))
            testCase.verifyEqual(timeIntervals.colnames, {'tags'})
        end

        function testCustomColumnUsesVectorDataSet(testCase)
            timeIntervals = types.core.TimeIntervals( ...
                'description', 'test time intervals');
            customColumn = types.hdmf_common.VectorData( ...
                'description', 'custom column', ...
                'data', single((1:3)'));

            timeIntervals.addColumn('custom_column', customColumn);

            testCase.verifyEqual( ...
                timeIntervals.vectordata.get('custom_column'), customColumn)
            testCase.verifyEqual(timeIntervals.colnames, {'custom_column'})
        end

        function testNonColumnPropertyCollisionErrors(testCase)
            units = types.core.Units('description', 'test units table');
            invalidColumn = types.hdmf_common.VectorData( ...
                'description', 'invalid column', ...
                'data', single((1:3)'));

            testCase.verifyError( ...
                @() units.addColumn( ...
                    'waveform_mean_sampling_rate', invalidColumn), ...
                'NWB:DynamicTable:AddColumn:InvalidPropertyCollision')
        end
    end
end
