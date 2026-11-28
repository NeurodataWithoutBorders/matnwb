classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...
        AddRowSchemaTypedColumnTest < matlab.unittest.TestCase
% AddRowSchemaTypedColumnTest - System tests for adding the first row to a
% column that the schema declares as a subtype of VectorData.

    methods (Test)
        function testFirstRowCreatesColumnOfSchemaClass(testCase)
            stimuliTable = types.core.IntracellularStimuliTable('colnames', {'stimulus'});

            stimuliTable.addRow('stimulus', testCase.createTimeSeriesReference());
            stimuliTable.addRow('stimulus', testCase.createTimeSeriesReference());

            testCase.verifyClass(stimuliTable.stimulus, ...
                'types.core.TimeSeriesReferenceVectorData')
            testCase.verifyNumElements(stimuliTable.stimulus.data, 2)
            testCase.verifyEqual(double(stimuliTable.id.data), [0; 1])
        end

        function testFirstRowCreatesEventsTableColumnsOfSchemaClass(testCase)
            eventsTable = types.core.EventsTable( ...
                'description', 'reward deliveries', ...
                'colnames', {'timestamp', 'duration'});

            eventsTable.addRow('timestamp', 12.5, 'duration', 0.2);
            eventsTable.addRow('timestamp', 31.0, 'duration', 0.4);

            testCase.verifyClass(eventsTable.timestamp, 'types.core.TimestampVectorData')
            testCase.verifyClass(eventsTable.duration, 'types.core.DurationVectorData')
            testCase.verifyEqual(eventsTable.timestamp.data(:), [12.5; 31.0])
            testCase.verifyEqual(eventsTable.duration.data(:), [0.2; 0.4])
            testCase.verifyEqual(double(eventsTable.id.data), [0; 1])
        end

        function testFirstRowCreatesPlainColumnAsVectorData(testCase)
            unitsTable = types.core.Units( ...
                'description', 'units', 'colnames', {'spike_times'});

            unitsTable.addRow('spike_times', [1; 2; 3]);

            testCase.verifyClass(unitsTable.spike_times, 'types.hdmf_common.VectorData')
        end

        function testFirstRowRejectsMissingRegionColumn(testCase)
            simultaneousTable = types.core.SimultaneousRecordingsTable( ...
                'description', 'simultaneous recordings', 'colnames', {'recordings'});

            testCase.verifyError( ...
                @() simultaneousTable.addRow('recordings', [0, 1]), ...
                'NWB:DynamicTable:AddRow:MissingRegionColumn')

            testCase.verifyEmpty(simultaneousTable.recordings)
        end

        function testAddRowToAssignedRegionColumn(testCase)
            recordingsTable = types.core.IntracellularRecordingsTable();
            simultaneousTable = types.core.SimultaneousRecordingsTable( ...
                'description', 'simultaneous recordings', ...
                'colnames', {'recordings'}, ...
                'recordings', types.hdmf_common.DynamicTableRegion( ...
                    'description', 'recordings of each simultaneous recording', ...
                    'table', types.untyped.ObjectView(recordingsTable)));

            simultaneousTable.addRow('recordings', [0, 1]);
            simultaneousTable.addRow('recordings', 2);

            testCase.verifyEqual(double(simultaneousTable.recordings.data(:)), [0; 1; 2])
            testCase.verifyEqual(double(simultaneousTable.recordings_index.data(:)), [2; 3])
        end

        function testAlignedTableAddRowCreatesTypedCategoryColumns(testCase)
            electrode = types.core.IntracellularElectrode( ...
                'description', 'electrode', ...
                'device', types.untyped.SoftLink(types.core.Device()));
            recordingsTable = types.core.IntracellularRecordingsTable();
            recordingsTable.electrodes = types.core.IntracellularElectrodesTable( ...
                'colnames', {'electrode'});
            recordingsTable.stimuli = types.core.IntracellularStimuliTable( ...
                'colnames', {'stimulus'});
            recordingsTable.responses = types.core.IntracellularResponsesTable( ...
                'colnames', {'response'});

            for iRow = 1:2
                recordingsTable.addRow( ...
                    'electrodes', struct('electrode', types.untyped.ObjectView(electrode)), ...
                    'stimuli', struct('stimulus', testCase.createTimeSeriesReference()), ...
                    'responses', struct('response', testCase.createTimeSeriesReference()));
            end

            testCase.verifyWarningFree(@() recordingsTable.ensureAlignedTableConsistency())
            testCase.verifyClass(recordingsTable.stimuli.stimulus, ...
                'types.core.TimeSeriesReferenceVectorData')
            testCase.verifyClass(recordingsTable.responses.response, ...
                'types.core.TimeSeriesReferenceVectorData')
            testCase.verifyEqual(double(recordingsTable.id.data), [0; 1])
            testCase.verifyEqual(double(recordingsTable.stimuli.id.data), [0; 1])
            testCase.verifyEqual(double(recordingsTable.responses.id.data), [0; 1])
        end
    end

    methods (Static, Access = private)
        function timeSeriesReference = createTimeSeriesReference()
            % One row of a TimeSeriesReferenceVectorData column, referring to
            % the 3 samples of a new TimeSeries.
            timeSeries = types.core.TimeSeries('data', [1, 2, 3], 'data_unit', 'n/a');
            timeSeriesReference = struct( ...
                'idx_start', 0, ...
                'count', 3, ...
                'timeseries', types.untyped.ObjectView(timeSeries));
        end
    end
end
