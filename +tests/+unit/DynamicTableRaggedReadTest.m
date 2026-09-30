classdef DynamicTableRaggedReadTest < tests.abstract.NwbTestCase
% DynamicTableRaggedReadTest - Tests for reading rows of ragged DynamicTable columns.
%
% The shared fixture is a Units table with four units and three ragged columns:
%   waveforms  doubly ragged. The units have 3, 0, 2 and 5 spikes, and each
%              spike is a [4 x 2] block: 4 samples on 2 electrodes.
%   labels     ragged text.
%   peaks      ragged compound, stored as a table.

    properties (TestParameter)
        RowIndices = struct( ...
            'firstRow', 1, ...
            'rowWithoutSpikes', 2, ...
            'allRows', 1:4, ...
            'rowsWithGap', [1 4], ...
            'unsortedRows', [4 2], ...
            'lastRow', 4)
    end

    properties (Access = private)
        FileName (1,1) string
        MemoryUnits
        FileUnits
    end

    methods (TestClassSetup)
        function exportUnitsTable(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);

            nwb = tests.factory.NWBFile();
            nwb.units = testCase.createUnitsTable();
            testCase.FileName = "ragged_read.nwb";
            nwbExport(nwb, testCase.FileName);

            testCase.MemoryUnits = nwb.units;
            nwbIn = nwbRead(testCase.FileName, 'ignorecache');
            testCase.FileUnits = nwbIn.units;
        end
    end

    methods (Test)
        function testGetRowFromFileMatchesMemory(testCase, RowIndices)
            testCase.verifyEqual( ...
                testCase.FileUnits.getRow(RowIndices), ...
                testCase.MemoryUnits.getRow(RowIndices));
        end

        function testToTableFromFileMatchesMemory(testCase)
            testCase.verifyEqual( ...
                testCase.FileUnits.toTable(), ...
                testCase.MemoryUnits.toTable());
        end

        function testGetRowFromBoundDataPipeMatchesUnbound(testCase, RowIndices)
            nwb = tests.factory.NWBFile();
            nwb.units = testCase.createUnitsTable(UseDataPipes=true);
            expectedRows = nwb.units.getRow(RowIndices, 'columns', {'waveforms'});

            % Exporting binds each DataPipe to its dataset in the file.
            nwbExport(nwb, testCase.getRandomFilename());
            testCase.assertTrue(nwb.units.waveforms.data.isBound)

            testCase.verifyEqual( ...
                nwb.units.getRow(RowIndices, 'columns', {'waveforms'}), ...
                expectedRows);
        end

        function testEmptyRowDoesNotDependOnOtherRequestedRows(testCase)
            % The second unit has no spike times.
            [spikeTimes, spikeTimesIndex] = util.create_indexed_column( ...
                {[1 2 3], zeros(1, 0), [4 5]});
            nwb = tests.factory.NWBFile();
            nwb.units = types.core.Units( ...
                'description', 'units with an empty row', ...
                'colnames', {'spike_times'}, ...
                'id', types.hdmf_common.ElementIdentifiers('data', int64(0:2)'), ...
                'spike_times', spikeTimes, ...
                'spike_times_index', spikeTimesIndex);
            fileName = testCase.getRandomFilename();
            nwbExport(nwb, fileName);
            nwbIn = nwbRead(fileName, 'ignorecache');

            testCase.verifyEmptyRowIsSameAloneAndWithOtherRows(nwb.units)
            testCase.verifyEmptyRowIsSameAloneAndWithOtherRows(nwbIn.units)
        end

        function testGetRowWhenColumnHasNoElements(testCase)
            % Every row of the column is empty, so its dataset has no
            % elements. An extendable dataset with nothing appended is
            % written that way.
            amplitudes = types.hdmf_common.VectorData( ...
                'description', 'amplitudes', ...
                'data', types.untyped.DataPipe('maxSize', Inf, 'dataType', 'double'));
            amplitudesIndex = types.hdmf_common.VectorIndex( ...
                'description', 'index into amplitudes', ...
                'data', uint64([0; 0]), ...
                'target', types.untyped.ObjectView(amplitudes));
            nwb = tests.factory.NWBFile();
            nwb.acquisition.set('rows_without_amplitudes', types.hdmf_common.DynamicTable( ...
                'description', 'table whose rows have no amplitudes', ...
                'colnames', {'amplitudes'}, ...
                'amplitudes', amplitudes, ...
                'amplitudes_index', amplitudesIndex, ...
                'id', types.hdmf_common.ElementIdentifiers('data', int64([0; 1]))));
            fileName = testCase.getRandomFilename();
            nwbExport(nwb, fileName);
            nwbIn = nwbRead(fileName, 'ignorecache');
            tableIn = nwbIn.acquisition.get('rows_without_amplitudes');

            vector = tableIn.vectordata.get('amplitudes');
            testCase.assertClass(vector.data, 'types.untyped.DataPipe')
            testCase.verifyRowsHaveNoAmplitudes(tableIn)

            vector.data = types.untyped.DataStub(fileName, '/acquisition/rows_without_amplitudes/amplitudes');
            testCase.verifyRowsHaveNoAmplitudes(tableIn)
        end

        function testGetRowReadsEachLevelOnce(testCase)
            [units, spies] = testCase.readUnitsWithSpies();

            units.getRow(1:4, 'columns', {'waveforms'});

            for columnName = string(fieldnames(spies))'
                testCase.verifyEqual(spies.(columnName).LoadCount, 1, ...
                    sprintf('Expected one read of "%s".', columnName));
            end
        end

        function testGetRowWithGapsReadsEachLevelOnce(testCase)
            % Units 1 and 4 are separated by units 2 and 3, and the waveforms
            % column is multi-dimensional, so the requested elements of each
            % level have a gap between them.
            [units, spies] = testCase.readUnitsWithSpies();

            units.getRow([1 4], 'columns', {'waveforms'});

            for columnName = string(fieldnames(spies))'
                testCase.verifyEqual(spies.(columnName).LoadCount, 1, ...
                    sprintf('Expected one read of "%s".', columnName));
            end
        end

        function testGetRowReadsOnlyRequestedElements(testCase)
            % Units 1 and 4 hold spikes 1-3 and 6-10, whose waveforms are
            % columns 1-6 and 11-20 of the data. Unit 3 lies between them.
            [units, spies] = testCase.readUnitsWithSpies();

            units.getRow([1 4], 'columns', {'waveforms'});

            testCase.verifyEqual(getReadElements(spies.waveforms_index_index), [1, 3, 4]);
            testCase.verifyEqual(getReadElements(spies.waveforms_index), [1:3, 5:10]);
            testCase.verifyEqual(getReadElements(spies.waveforms), [1:6, 11:20]);
        end
    end

    methods (Access = private)
        function [units, spies] = readUnitsWithSpies(testCase)
            % readUnitsWithSpies - Read the units table with a spy on each dataset of the waveforms column.
            nwbIn = nwbRead(testCase.FileName, 'ignorecache');
            units = nwbIn.units;
            spies = struct();
            for columnName = ["waveforms", "waveforms_index", "waveforms_index_index"]
                vector = units.(columnName);
                spy = tests.unit.io.backend.doubles.HDF5LazyArraySpy( ...
                    vector.data.filename, vector.data.path);
                vector.data = types.untyped.DataStub( ...
                    vector.data.filename, vector.data.path, [], [], spy);
                % Assigning data runs validation, which also reads the dataset.
                spy.reset()
                spies.(columnName) = spy;
            end
        end

        function verifyRowsHaveNoAmplitudes(testCase, dynamicTable)
            rows = dynamicTable.getRow(1:2);
            testCase.verifyEqual(rows.amplitudes, {zeros(0, 0); zeros(0, 0)});
            testCase.verifyEqual(height(dynamicTable.toTable()), 2);
        end

        function verifyEmptyRowIsSameAloneAndWithOtherRows(testCase, units)
            emptyRowAlone = units.getRow(2).spike_times{1};
            allRows = units.getRow(1:3);
            testCase.verifyEqual(allRows.spike_times{2}, emptyRowAlone);
        end
    end

    methods (Static, Access = private)
        function units = createUnitsTable(options)
            arguments
                options.UseDataPipes (1,1) logical = false
            end

            spikesPerUnit = [3 0 2 5];
            numSamples = 4;
            numElectrodes = 2;
            numSpikes = sum(spikesPerUnit);

            % Each column of waveformData is the waveform of one spike on one electrode.
            waveformData = reshape(1:(numSamples*numElectrodes*numSpikes), numSamples, []);
            waveformsIndexData = uint64(numElectrodes:numElectrodes:(numElectrodes*numSpikes))';
            waveformsIndexIndexData = uint64(cumsum(spikesPerUnit))';
            if options.UseDataPipes
                waveformData = types.untyped.DataPipe( ...
                    'data', waveformData, 'maxSize', [numSamples, Inf], 'axis', 2);
                waveformsIndexData = types.untyped.DataPipe( ...
                    'data', waveformsIndexData, 'maxSize', Inf);
                waveformsIndexIndexData = types.untyped.DataPipe( ...
                    'data', waveformsIndexIndexData, 'maxSize', Inf);
            end

            waveforms = types.hdmf_common.VectorData( ...
                'description', 'waveforms', ...
                'data', waveformData);
            waveformsIndex = types.hdmf_common.VectorIndex( ...
                'description', 'index into waveforms, one row per spike', ...
                'data', waveformsIndexData, ...
                'target', types.untyped.ObjectView(waveforms));
            waveformsIndexIndex = types.hdmf_common.VectorIndex( ...
                'description', 'index into waveforms_index, one row per unit', ...
                'data', waveformsIndexIndexData, ...
                'target', types.untyped.ObjectView(waveformsIndex));

            units = types.core.Units( ...
                'description', 'units with ragged columns', ...
                'colnames', {'waveforms'}, ...
                'id', types.hdmf_common.ElementIdentifiers('data', int64(0:3)'), ...
                'waveforms', waveforms, ...
                'waveforms_index', waveformsIndex, ...
                'waveforms_index_index', waveformsIndexIndex);

            labels = types.hdmf_common.VectorData( ...
                'description', 'labels', ...
                'data', {'a'; 'b'; 'c'; 'd'; 'e'; 'f'; 'g'});
            labelsIndex = types.hdmf_common.VectorIndex( ...
                'description', 'index into labels', ...
                'data', uint64([2; 3; 4; 7]), ...
                'target', types.untyped.ObjectView(labels));
            units.addColumn('labels', labels, 'labels_index', labelsIndex);

            peaks = types.hdmf_common.VectorData( ...
                'description', 'peaks', ...
                'data', table((1:6)', (11:16)', 'VariableNames', {'amplitude', 'time'}));
            peaksIndex = types.hdmf_common.VectorIndex( ...
                'description', 'index into peaks', ...
                'data', uint64([1; 3; 4; 6]), ...
                'target', types.untyped.ObjectView(peaks));
            units.addColumn('peaks', peaks, 'peaks_index', peaksIndex);
        end
    end
end

function elements = getReadElements(spy)
% getReadElements - Sorted elements that a spy's reads selected in their last subscript.
lastSubscripts = cellfun(@(selection) reshape(selection{end}, 1, []), ...
    spy.Selections, 'UniformOutput', false);
elements = sort([lastSubscripts{:}]);
end
