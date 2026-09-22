classdef TimeSeriesTest < tests.abstract.NwbTestCase
% TimeSeriesTest - Unit tests for handwritten TimeSeries behavior.

    methods (TestClassSetup)
        function setupTemporaryWorkingFolder(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testGetDataInUnitsWithDefaults(testCase)
            % An unmodified TimeSeries uses conversion 1 and offset 0, so
            % the data is returned unchanged.
            timeSeries = types.core.TimeSeries( ...
                'data', [1; 2; 3], 'data_unit', 'volts');

            testCase.verifyEqual(timeSeries.getDataInUnits(), [1; 2; 3])
        end

        function testGetDataInUnitsWithConversion(testCase)
            timeSeries = types.core.TimeSeries( ...
                'data', [1; 2; 3], 'data_unit', 'volts', 'data_conversion', 2);

            testCase.verifyEqual(timeSeries.getDataInUnits(), [2; 4; 6])
        end

        function testGetDataInUnitsWithConversionAndOffset(testCase)
            timeSeries = types.core.TimeSeries( ...
                'data', [1; 2; 3], 'data_unit', 'volts', ...
                'data_conversion', 2, 'data_offset', 3);

            testCase.verifyEqual(timeSeries.getDataInUnits(), [5; 7; 9])
        end

        function testGetDataInUnitsPromotesIntegerData(testCase)
            % Integer arithmetic in MATLAB rounds and saturates, so the raw
            % data must be promoted to a floating point type before the
            % conversion factor is applied.
            timeSeries = types.core.TimeSeries( ...
                'data', int16([1; 2; 3]), 'data_unit', 'volts', ...
                'data_conversion', 2.5);

            dataInUnits = timeSeries.getDataInUnits();
            testCase.verifyClass(dataInUnits, 'double')
            testCase.verifyEqual(dataInUnits, [2.5; 5; 7.5])
        end

        function testGetDataInUnitsDoesNotSaturateIntegerData(testCase)
            timeSeries = types.core.TimeSeries( ...
                'data', int16([30000; -30000]), 'data_unit', 'volts', ...
                'data_conversion', 2);

            testCase.verifyEqual(timeSeries.getDataInUnits(), [60000; -60000])
        end

        function testGetDataInUnitsPreservesSingleData(testCase)
            timeSeries = types.core.TimeSeries( ...
                'data', single([1; 2; 3]), 'data_unit', 'volts', ...
                'data_conversion', 2);

            dataInUnits = timeSeries.getDataInUnits();
            testCase.verifyClass(dataInUnits, 'single')
            testCase.verifyEqual(dataInUnits, single([2; 4; 6]))
        end

        function testGetDataInUnitsWithDataPipe(testCase)
            timeSeries = types.core.TimeSeries( ...
                'data', types.untyped.DataPipe('data', [1; 2; 3]), ...
                'data_unit', 'volts', 'data_conversion', 2);

            testCase.verifyEqual(timeSeries.getDataInUnits(), [2; 4; 6])
        end

        function testGetDataInUnitsOnReadFile(testCase)
            % Data is a DataStub after reading, and has to be loaded before
            % the conversion can be applied.
            nwbFile = tests.factory.NWBFile();
            nwbFile.acquisition.set('TimeSeries', types.core.TimeSeries( ...
                'data', int16([1; 2; 3]), 'data_unit', 'volts', ...
                'data_conversion', 2, 'data_offset', 1, ...
                'starting_time', 0, 'starting_time_rate', 1));

            nwbFilePath = testCase.getRandomFilename();
            nwbExport(nwbFile, nwbFilePath)
            nwbFileIn = nwbRead(nwbFilePath, 'ignorecache');

            timeSeries = nwbFileIn.acquisition.get('TimeSeries');
            testCase.assertClass(timeSeries.data, 'types.untyped.DataStub')
            testCase.verifyEqual(timeSeries.getDataInUnits(), [3; 5; 7])
        end

        function testGetDataInUnitsWithChannelConversion(testCase)
            % In MatNWB the dimensions of a dataset are reversed relative
            % to the file, so an ElectricalSeries holds channels along the
            % first dimension and the channel conversion applies to rows.
            numSamples = 10;
            conversion = 10;
            offset = 3;
            % Exactly representable as single, which is the type the
            % channel conversion is stored as.
            channelConversion = [0.5; 0.25; 0.125; 2; 4];
            numChannels = numel(channelConversion);

            electricalSeries = types.core.ElectricalSeries( ...
                'data', ones(numChannels, numSamples), ...
                'data_conversion', conversion, ...
                'data_offset', offset, ...
                'channel_conversion', channelConversion);

            dataInUnits = electricalSeries.getDataInUnits();

            testCase.verifySize(dataInUnits, [numChannels, numSamples])
            for iChannel = 1:numChannels
                testCase.verifyEqual( ...
                    dataInUnits(iChannel, :), ...
                    ones(1, numSamples) * conversion * channelConversion(iChannel) + offset)
            end
        end

        function testGetDataInUnitsWithScalarChannelConversion(testCase)
            % A single channel conversion factor applies to the whole
            % array, independent of which dimension holds the channels.
            electricalSeries = types.core.ElectricalSeries( ...
                'data', ones(1, 10), ...
                'data_conversion', 2, ...
                'channel_conversion', 4);

            testCase.verifyEqual( ...
                electricalSeries.getDataInUnits(), ones(1, 10) * 8)
        end

        function testGetDataInUnitsWithMismatchedChannelConversion(testCase)
            electricalSeries = types.core.ElectricalSeries( ...
                'data', ones(5, 10), ...
                'channel_conversion', ones(4, 1));

            testCase.verifyError( ...
                @() electricalSeries.getDataInUnits(), ...
                'NWB:TimeSeries:GetDataInUnits:ChannelConversionMismatch')
        end

        function testGetDataInUnitsWithNonNumericData(testCase)
            annotationSeries = types.core.AnnotationSeries( ...
                'data', {'a'; 'b'; 'c'}, 'timestamps', [1; 2; 3]);

            testCase.verifyError( ...
                @() annotationSeries.getDataInUnits(), ...
                'NWB:TimeSeries:GetDataInUnits:NonNumericData')
        end
    end
end
