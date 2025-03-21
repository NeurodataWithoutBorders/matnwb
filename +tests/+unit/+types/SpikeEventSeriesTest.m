classdef SpikeEventSeriesTest < tests.abstract.NwbTestCase

    methods (TestClassSetup)
        function setupTemporaryWorkingFolder(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testExportSpikeEventSeries(testCase)

            nwbFile = tests.factory.NWBFile();
            electrodeTable = tests.factory.ElectrodeTable(nwbFile);

            electrodeReference = types.hdmf_common.DynamicTableRegion( ...
                'table', types.untyped.ObjectView(electrodeTable), ...
                'description', 'test electrodes', ...
                'data', (0:length(electrodeTable.id.data)-1)');

            spikeEventSeries = types.core.SpikeEventSeries(...
                'electrodes', electrodeReference, ...
                'data', rand(1,10), ...
                'starting_time', 0, ...
                'starting_time_rate', 1);

            processingModule = types.core.ProcessingModule('description', 'ecephys');
            nwbFile.processing.set('Ecephys', processingModule);

            processingModule.nwbdatainterface.set('SpikeEventSeries', spikeEventSeries);

            nwbFilePath = testCase.getRandomFilename();
            testCase.verifyError( ...
                @() nwbExport(nwbFile, nwbFilePath), ...
                'NWB:RequiredPropertyMissing')

            processingModule.nwbdatainterface.remove('SpikeEventSeries');


            % Add timestamps and verify that export works
            spikeEventSeries = types.core.SpikeEventSeries(...
                'electrodes', electrodeReference, ...
                'data', rand(1,10), ...
                'timestamps', rand(1,10));
            processingModule.nwbdatainterface.set('SpikeEventSeries', spikeEventSeries);
            
            nwbFilePath = testCase.getRandomFilename();
            nwbExport(nwbFile, nwbFilePath)
        end
    end
end
