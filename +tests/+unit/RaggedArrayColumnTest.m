classdef RaggedArrayColumnTest < tests.abstract.NwbTestCase
% RaggedArrayColumnTest - Tests for passing a types.untyped.RaggedArrayColumn
% to a DynamicTable constructor and to addColumn.

    properties (Constant)
        SpikeTimes = {[0.1 0.2 0.3], [0.5 0.6]}
        SpikeTimesDescription = "spike times of each unit, in seconds"
    end

    methods (Test)
        function testConstructorStoresSameObjectsAsMethod(testCase)
            spikeTimes = types.untyped.RaggedArrayColumn(testCase.SpikeTimes, ...
                Description=testCase.SpikeTimesDescription);
            fromConstructor = types.core.Units('colnames', {'spike_times'}, ...
                'description', 'units', 'spike_times', spikeTimes);

            fromMethod = testCase.createUnitsWithMethod();
            testCase.verifySameColumns(fromConstructor, fromMethod)
        end

        function testAddColumnStoresSameObjectsAsMethod(testCase)
            spikeTimes = types.untyped.RaggedArrayColumn(testCase.SpikeTimes, ...
                Description=testCase.SpikeTimesDescription);
            fromAddColumn = types.core.Units('colnames', {}, 'description', 'units');
            fromAddColumn.addColumn('spike_times', spikeTimes);

            fromMethod = testCase.createUnitsWithMethod();
            testCase.verifySameColumns(fromAddColumn, fromMethod)
        end

        function testAddColumnTakesRaggedAndPlainColumnsInOneCall(testCase)
            spikeTimes = types.untyped.RaggedArrayColumn(testCase.SpikeTimes);
            quality = types.hdmf_common.VectorData('description', 'unit quality', ...
                'data', [0.9; 0.4]);
            dynamicTable = types.hdmf_common.DynamicTable('description', 'units');
            dynamicTable.addColumn('quality', quality, 'spike_times', spikeTimes);

            testCase.verifyEqual(sort(dynamicTable.colnames), {'quality', 'spike_times'});
            testCase.verifyEqual(dynamicTable.vectordata.get('spike_times_index').data, uint64([3; 5]));
            testCase.verifyEqual(dynamicTable.id.data, int64([0; 1]));
        end

        function testConstructorStoresDoublyRaggedColumn(testCase)
            waveforms = types.untyped.RaggedArrayColumn({{[1 2], [3 4 5]}, {6}}, Depth=2);
            dynamicTable = types.hdmf_common.DynamicTable('description', 'units', ...
                'colnames', {'waveforms'}, 'waveforms', waveforms);

            testCase.verifyEqual(dynamicTable.vectordata.get('waveforms_index').data, uint64([2; 5; 6]));
            testCase.verifyEqual(dynamicTable.vectordata.get('waveforms_index_index').data, uint64([2; 3]));
            testCase.verifyEqual(dynamicTable.id.data, int64([0; 1]));
        end

        function testConstructorRejectsIndexGivenTwice(testCase)
            spikeTimes = types.untyped.RaggedArrayColumn(testCase.SpikeTimes);
            index = types.hdmf_common.VectorIndex('description', 'index', 'data', uint64([3; 5]));

            testCase.verifyError(@() types.core.Units('colnames', {'spike_times'}, ...
                'description', 'units', 'spike_times', spikeTimes, 'spike_times_index', index), ...
                'NWB:DynamicTable:ExpandableTableColumn:DuplicateArgument')
        end

        function testAddColumnRejectsIndexGivenTwice(testCase)
            spikeTimes = types.untyped.RaggedArrayColumn(testCase.SpikeTimes);
            index = types.hdmf_common.VectorIndex('description', 'index', 'data', uint64([3; 5]));
            dynamicTable = types.hdmf_common.DynamicTable('description', 'units');

            testCase.verifyError(@() dynamicTable.addColumn('spike_times', spikeTimes, ...
                'spike_times_index', index), 'NWB:DynamicTable:ExpandableTableColumn:DuplicateArgument')
            testCase.verifyEmpty(dynamicTable.colnames)
        end
    end

    methods (Access = private)
        function units = createUnitsWithMethod(testCase)
            units = types.core.Units('colnames', {}, 'description', 'units');
            units.addRaggedArrayColumn('spike_times', testCase.SpikeTimes, ...
                Description=testCase.SpikeTimesDescription);
        end

        function verifySameColumns(testCase, actualUnits, expectedUnits)
            testCase.verifyEqual(actualUnits.colnames, expectedUnits.colnames);
            testCase.verifyEqual(actualUnits.spike_times.data, expectedUnits.spike_times.data);
            testCase.verifyEqual(actualUnits.spike_times.description, ...
                expectedUnits.spike_times.description);
            testCase.verifyEqual(actualUnits.spike_times_index.data, ...
                expectedUnits.spike_times_index.data);
            testCase.verifyEqual(actualUnits.id.data, expectedUnits.id.data);
        end
    end
end
