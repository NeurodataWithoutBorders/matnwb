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

        function testGetRowReadsEachLevelOnce(testCase)
            nwbIn = nwbRead(testCase.FileName, 'ignorecache');
            columnNames = ["waveforms", "waveforms_index", "waveforms_index_index"];
            spies = cell(size(columnNames));
            for iColumn = 1:numel(columnNames)
                vector = nwbIn.units.(columnNames(iColumn));
                spies{iColumn} = tests.unit.io.backend.doubles.HDF5LazyArraySpy( ...
                    vector.data.filename, vector.data.path);
                vector.data = types.untyped.DataStub( ...
                    vector.data.filename, vector.data.path, [], [], spies{iColumn});
            end
            % Assigning data runs validation, which also reads the dataset.
            loadCountBefore = cellfun(@(spy) spy.LoadCount, spies);

            nwbIn.units.getRow(1:4, 'columns', {'waveforms'});

            for iColumn = 1:numel(columnNames)
                testCase.verifyEqual(spies{iColumn}.LoadCount - loadCountBefore(iColumn), 1, ...
                    sprintf('Expected one read of "%s".', columnNames(iColumn)));
            end
        end
    end

    methods (Access = private)
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
