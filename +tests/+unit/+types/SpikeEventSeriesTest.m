classdef SpikeEventSeriesTest < tests.abstract.NwbTestCase

    methods (TestClassSetup)
        function setupTemporaryWorkingFolder(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testExportSpikeEventSeries(testCase)

            % This test should only run for NWB v2.9.0 or newer
            versionToTest = [2, 9, 0];

            currentVersionStr = types.core.Version();
            currentVersionNum = str2double( strsplit(currentVersionStr, '.') );
            
            for i = 1:3
                if currentVersionNum(i) < versionToTest(i)
                    return
                elseif currentVersionNum(i) > versionToTest(i)
                    break
                elseif currentVersionNum(i) == versionToTest(i)
                    continue
                end
            end

            nwbFile = tests.factory.NWBFile();
            electrodeTable = tests.factory.ElectrodeTable(nwbFile);

            electrodeReference = types.hdmf_common.DynamicTableRegion( ...
                'table', types.untyped.ObjectView(electrodeTable), ...
                'description', 'test electrodes', ...
                'data', (0:length(electrodeTable.id.data)-1)');

            % Create a spike event series using starting time instead of
            % timestamps. This should fail on export because timestamps is
            % a required property of SpikeEventSeries.
            spikeEventSeries = types.core.SpikeEventSeries(...
                'electrodes', electrodeReference, ...
                'data', rand(1,10), ...
                'starting_time', 0, ...
                'starting_time_rate', 1);

            processingModule = types.core.ProcessingModule('description', 'ecephys');
            processingModule.nwbdatainterface.set('SpikeEventSeries', spikeEventSeries);
            nwbFile.processing.set('Ecephys', processingModule);

            % Verify that export fails
            nwbFilePath = testCase.getRandomFilename();
            testCase.verifyError( ...
                @() nwbExport(nwbFile, nwbFilePath), ...
                'NWB:RequiredPropertyMissing')

            processingModule.nwbdatainterface.remove('SpikeEventSeries');

            % Create a new spike event series with proper timestamps and verify 
            % that export works
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
