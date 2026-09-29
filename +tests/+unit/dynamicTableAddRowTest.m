classdef dynamicTableAddRowTest < tests.abstract.NwbTestCase
% dynamicTableAddRowTest - Tests for adding rows with vector and ragged
% values to a DynamicTable through addRow.

    methods (Test)
        function testAddRowWithoutColnamesThrowsNoColumns(testCase)
            dynamicTable = types.hdmf_common.DynamicTable( ...
                'description', 'test table');

            testCase.verifyError(@() dynamicTable.addRow('spike_times', [1; 2]), ...
                'NWB:DynamicTable:AddRow:NoColumns');
        end

        function testAddRowBuildsRaggedColumn(testCase)
            dynamicTable = testCase.createTable('spike_times');

            dynamicTable.addRow('spike_times', [1; 2; 3]);
            dynamicTable.addRow('spike_times', [4; 5]);

            testCase.verifyEqual(dynamicTable.vectordata.get('spike_times').data, (1:5)');
            testCase.verifyEqual(double(dynamicTable.vectordata.get('spike_times_index').data), [3; 5]);
        end

        function testAddRowTurnsRegularColumnRagged(testCase)
            dynamicTable = testCase.createTable('spike_times');

            dynamicTable.addRow('spike_times', 1);
            dynamicTable.addRow('spike_times', [2; 3]);

            testCase.verifyEqual(dynamicTable.vectordata.get('spike_times').data, [1; 2; 3]);
            testCase.verifyEqual(double(dynamicTable.vectordata.get('spike_times_index').data), [1; 3]);
        end

        function testAddRowAppendsRowVectorToColumnVectorData(testCase)
            dynamicTable = testCase.createTable('spike_times');

            dynamicTable.addRow('spike_times', [1; 2; 3]);
            dynamicTable.addRow('spike_times', [4, 5]);

            testCase.verifyEqual(dynamicTable.vectordata.get('spike_times').data, (1:5)');
            testCase.verifyEqual(double(dynamicTable.vectordata.get('spike_times_index').data), [3; 5]);
        end

        function testAddRowAppendsColumnVectorToRowVectorData(testCase)
            dynamicTable = testCase.createTable('spike_times');

            dynamicTable.addRow('spike_times', [1, 2, 3]);
            dynamicTable.addRow('spike_times', [4; 5]);

            testCase.verifyEqual(dynamicTable.vectordata.get('spike_times').data, 1:5);
            testCase.verifyEqual(double(dynamicTable.vectordata.get('spike_times_index').data), [3; 5]);
        end

        function testAddRowAppendsRowCellToCellstrColumn(testCase)
            dynamicTable = testCase.createTable('tags');

            dynamicTable.addRow('tags', {'a'; 'b'});
            dynamicTable.addRow('tags', {'c', 'd'});

            testCase.verifyEqual(dynamicTable.vectordata.get('tags').data, {'a'; 'b'; 'c'; 'd'});
            testCase.verifyEqual(double(dynamicTable.vectordata.get('tags_index').data), [2; 4]);
        end

        function testAddRowAppendsToDoublyRaggedColumn(testCase)
            % Each row is a cell with one [numSamples x numWaveforms] matrix
            % per sub-group.
            dynamicTable = testCase.createTable('waveforms');

            dynamicTable.addRow('waveforms', {rand(4, 3), rand(4, 3)});
            dynamicTable.addRow('waveforms', {rand(4, 3), rand(4, 3), rand(4, 3)});

            testCase.verifySize(dynamicTable.vectordata.get('waveforms').data, [4, 15]);
            testCase.verifyEqual(double(dynamicTable.vectordata.get('waveforms_index').data), ...
                [3; 6; 9; 12; 15]);
            testCase.verifyEqual(double(dynamicTable.vectordata.get('waveforms_index_index').data), ...
                [2; 5]);
        end

        function testAddRowRejectsValueWithExtraIndexLevel(testCase)
            dynamicTable = testCase.createTable('waveforms');
            dynamicTable.addRow('waveforms', {rand(4, 3), rand(4, 3)});

            % The row is wrapped in one cell too many.
            testCase.verifyError( ...
                @() dynamicTable.addRow('waveforms', {{rand(4, 3), rand(4, 3)}}), ...
                'NWB:DynamicTable:AddRow:TooManyIndexLevels');
            testCase.verifyFalse(dynamicTable.vectordata.isKey('waveforms_index_index_index'));
            testCase.verifyEqual(double(dynamicTable.vectordata.get('waveforms_index_index').data), 2);
        end
    end

    methods (Static, Access = private)
        function dynamicTable = createTable(columnName)
            dynamicTable = types.hdmf_common.DynamicTable( ...
                'description', 'test table', ...
                'colnames', {columnName});
        end
    end
end
