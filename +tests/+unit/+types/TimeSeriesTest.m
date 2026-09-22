classdef TimeSeriesTest < tests.abstract.NwbTestCase
% TimeSeriesTest - Unit tests for handwritten TimeSeries behavior.

    properties (Constant, Access = private)
        % Every factor is exactly representable as single, the type
        % channel_conversion is stored as, so the expected values in the
        % tests below are exact.
        ChannelConversion = [0.5; 0.25; 0.125; 2; 4]
    end

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

        function testGetDataInUnitsWithThreeDimensionalData(testCase)
            % ElectricalSeries data can be [samples x channels x time] in
            % MatNWB, which puts the channels along the second dimension
            % and so exercises the reshaping of the conversion factors.
            channelConversion = testCase.ChannelConversion;
            numChannels = numel(channelConversion);
            conversion = 10;
            offset = 3;

            electricalSeries = types.core.ElectricalSeries( ...
                'data', ones(4, numChannels, 6), ...
                'data_conversion', conversion, ...
                'data_offset', offset, ...
                'channel_conversion', channelConversion);

            dataInUnits = electricalSeries.getDataInUnits();

            testCase.verifySize(dataInUnits, [4, numChannels, 6])
            for iChannel = 1:numChannels
                testCase.verifyEqual( ...
                    dataInUnits(:, iChannel, :), ...
                    ones(4, 1, 6) * conversion * channelConversion(iChannel) + offset)
            end
        end

        function testApplyConversionOnTimeSliceOfThreeDimensionalData(testCase)
            % A time slice of [samples x channels x time] data comes back
            % two-dimensional, because MATLAB drops trailing singleton
            % dimensions. The channels still lie along the second
            % dimension, which has to be found from the rank of the stored
            % data rather than from the rank of the slice.
            channelConversion = testCase.ChannelConversion;
            numChannels = numel(channelConversion);
            numSamples = 4;
            numTimes = 6;
            data = reshape(1:(numSamples*numChannels*numTimes), ...
                numSamples, numChannels, numTimes);

            electricalSeries = types.core.ElectricalSeries( ...
                'data', data, ...
                'data_conversion', 10, ...
                'data_offset', 3, ...
                'channel_conversion', channelConversion);
            dataInUnits = electricalSeries.getDataInUnits();

            timeSlice = electricalSeries.data(:, :, 2);
            testCase.assertSize(timeSlice, [numSamples, numChannels])

            testCase.verifyEqual( ...
                electricalSeries.applyConversion(timeSlice), ...
                dataInUnits(:, :, 2))

            selectedChannels = [4 2];
            testCase.verifyEqual( ...
                electricalSeries.applyConversion( ...
                    timeSlice(:, selectedChannels), 'Channels', selectedChannels), ...
                dataInUnits(:, selectedChannels, 2))
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
                'NWB:TimeSeries:ApplyConversion:ChannelConversionMismatch')
        end

        function testGetDataInUnitsWithNonNumericData(testCase)
            annotationSeries = types.core.AnnotationSeries( ...
                'data', {'a'; 'b'; 'c'}, 'timestamps', [1; 2; 3]);

            testCase.verifyError( ...
                @() annotationSeries.getDataInUnits(), ...
                'NWB:TimeSeries:ApplyConversion:NonNumericData')
        end

        function testApplyConversionOnSubsetOfData(testCase)
            % Without a channel conversion the scaling is elementwise, so a
            % subset scales the same way the whole dataset does.
            timeSeries = types.core.TimeSeries( ...
                'data', (1:10)', 'data_unit', 'volts', ...
                'data_conversion', 2, 'data_offset', 1);

            dataInUnits = timeSeries.getDataInUnits();
            subsetInUnits = timeSeries.applyConversion(timeSeries.data(3:5));

            testCase.verifyEqual(subsetInUnits, dataInUnits(3:5))
            testCase.verifyEqual(subsetInUnits, [7; 9; 11])
        end

        function testApplyConversionOnLazySubsetOfReadFile(testCase)
            % The case applyConversion exists for: scale a subset loaded
            % from a DataStub without reading the whole dataset.
            nwbFile = tests.factory.NWBFile();
            nwbFile.acquisition.set('TimeSeries', types.core.TimeSeries( ...
                'data', int16([1; 2; 3; 4; 5]), 'data_unit', 'volts', ...
                'data_conversion', 2, 'data_offset', 1, ...
                'starting_time', 0, 'starting_time_rate', 1));

            nwbFilePath = testCase.getRandomFilename();
            nwbExport(nwbFile, nwbFilePath)
            nwbFileIn = nwbRead(nwbFilePath, 'ignorecache');

            timeSeries = nwbFileIn.acquisition.get('TimeSeries');
            testCase.assertClass(timeSeries.data, 'types.untyped.DataStub')

            dataInUnits = timeSeries.getDataInUnits();
            subsetInUnits = timeSeries.applyConversion(timeSeries.data(2:4));

            testCase.verifyEqual(subsetInUnits, dataInUnits(2:4))
            testCase.verifyEqual(subsetInUnits, [5; 7; 9])
        end

        function testApplyConversionPromotesIntegerData(testCase)
            % Without promotion to double the conversion would saturate at
            % the limits of int16.
            timeSeries = types.core.TimeSeries( ...
                'data', int16([30000; -30000]), 'data_unit', 'volts', ...
                'data_conversion', 2.5);

            dataInUnits = timeSeries.applyConversion(timeSeries.data);

            testCase.verifyClass(dataInUnits, 'double')
            testCase.verifyEqual(dataInUnits, [75000; -75000])
        end

        function testApplyConversionWithChannelSelection(testCase)
            electricalSeries = testCase.createElectricalSeries();
            dataInUnits = electricalSeries.getDataInUnits();

            selectedChannels = 3:5;
            subsetInUnits = electricalSeries.applyConversion( ...
                electricalSeries.data(selectedChannels, :), ...
                'Channels', selectedChannels);

            testCase.verifyEqual(subsetInUnits, dataInUnits(selectedChannels, :))
        end

        function testApplyConversionWithReorderedChannelSelection(testCase)
            % The conversion factors follow the order of the channels in
            % the data, not their order in channel_conversion.
            electricalSeries = testCase.createElectricalSeries();
            dataInUnits = electricalSeries.getDataInUnits();

            selectedChannels = [5 1 3];
            subsetInUnits = electricalSeries.applyConversion( ...
                electricalSeries.data(selectedChannels, :), ...
                'Channels', selectedChannels);

            testCase.verifyEqual(subsetInUnits, dataInUnits(selectedChannels, :))
        end

        function testApplyConversionWithColumnChannelSelection(testCase)
            % Channel indices are often produced by find, which returns a
            % column, so both orientations are accepted.
            electricalSeries = testCase.createElectricalSeries();
            dataInUnits = electricalSeries.getDataInUnits();

            selectedChannels = [2; 4];
            subsetInUnits = electricalSeries.applyConversion( ...
                electricalSeries.data(selectedChannels, :), ...
                'Channels', selectedChannels);

            testCase.verifyEqual(subsetInUnits, dataInUnits(selectedChannels, :))
        end

        function testApplyConversionRequiresChannelSelectionForPartialData(testCase)
            % Guessing which channels a partial load holds would silently
            % scale the data with the wrong factors.
            electricalSeries = testCase.createElectricalSeries();

            testCase.verifyError( ...
                @() electricalSeries.applyConversion(electricalSeries.data(3:5, :)), ...
                'NWB:TimeSeries:ApplyConversion:ChannelSelectionRequired')
        end

        function testApplyConversionWithWrongNumberOfChannels(testCase)
            electricalSeries = testCase.createElectricalSeries();

            testCase.verifyError( ...
                @() electricalSeries.applyConversion( ...
                    electricalSeries.data(3:5, :), 'Channels', 3:4), ...
                'NWB:TimeSeries:ApplyConversion:InvalidChannelSelection')
        end

        function testApplyConversionWithOutOfRangeChannels(testCase)
            electricalSeries = testCase.createElectricalSeries();

            testCase.verifyError( ...
                @() electricalSeries.applyConversion( ...
                    electricalSeries.data(3:5, :), 'Channels', 4:6), ...
                'NWB:TimeSeries:ApplyConversion:InvalidChannelSelection')
        end

        function testApplyConversionDetectsInconsistentTimeSeriesOnSubset(testCase)
            % The channel count is taken from the data of the TimeSeries,
            % so a subset cannot hide a channel_conversion of the wrong
            % length: neither one that happens to match the subset's size
            % nor one that would otherwise look like a partial load.
            electricalSeries = types.core.ElectricalSeries( ...
                'data', ones(5, 10), 'channel_conversion', ones(4, 1));

            testCase.verifyError( ...
                @() electricalSeries.applyConversion(electricalSeries.data(1:4, :)), ...
                'NWB:TimeSeries:ApplyConversion:ChannelConversionMismatch')
            testCase.verifyError( ...
                @() electricalSeries.applyConversion(electricalSeries.data(1:3, :)), ...
                'NWB:TimeSeries:ApplyConversion:ChannelConversionMismatch')
        end

        function testApplyConversionWithDataFromAnotherTimeSeries(testCase)
            % More channels than the TimeSeries has cannot be a subset of
            % its data, so it is reported rather than scaled.
            electricalSeries = testCase.createElectricalSeries();

            testCase.verifyError( ...
                @() electricalSeries.applyConversion(ones(7, 3)), ...
                'NWB:TimeSeries:ApplyConversion:DataMismatch')
        end

        function testApplyConversionOnLazySubsetOfElectricalSeries(testCase)
            % After a round trip the data and the channel_conversion are
            % both DataStubs, and the channel count has to come from the
            % dims of the data stub without loading it.
            channelConversion = testCase.ChannelConversion;
            numChannels = numel(channelConversion);

            nwbFile = tests.factory.NWBFile();
            electrodeTable = tests.factory.ElectrodeTable(nwbFile);
            electrodeGroup = nwbFile.general_extracellular_ephys.get('ElectrodeGroup');
            for iElectrode = 2:numChannels
                electrodeTable.addRow( ...
                    'location', 'unknown', ...
                    'group', types.untyped.ObjectView(electrodeGroup), ...
                    'group_name', 'test electrode group', ...
                    'label', sprintf('test electrode %d', iElectrode));
            end
            electrodes = types.hdmf_common.DynamicTableRegion( ...
                'table', types.untyped.ObjectView(electrodeTable), ...
                'description', 'all electrodes', ...
                'data', (0:numChannels-1)');

            nwbFile.acquisition.set('ElectricalSeries', types.core.ElectricalSeries( ...
                'data', int16(reshape(1:numChannels*7, numChannels, 7)), ...
                'electrodes', electrodes, ...
                'data_conversion', 10, 'data_offset', 3, ...
                'channel_conversion', channelConversion, ...
                'starting_time', 0, 'starting_time_rate', 1));

            nwbFilePath = testCase.getRandomFilename();
            nwbExport(nwbFile, nwbFilePath)
            electricalSeries = nwbRead(nwbFilePath, 'ignorecache').acquisition.get('ElectricalSeries');
            testCase.assertClass(electricalSeries.data, 'types.untyped.DataStub')

            dataInUnits = electricalSeries.getDataInUnits();
            selectedChannels = 2:4;
            subsetInUnits = electricalSeries.applyConversion( ...
                electricalSeries.data(selectedChannels, :), ...
                'Channels', selectedChannels);

            testCase.verifyEqual(subsetInUnits, dataInUnits(selectedChannels, :))
            testCase.verifyError( ...
                @() electricalSeries.applyConversion(electricalSeries.data(selectedChannels, :)), ...
                'NWB:TimeSeries:ApplyConversion:ChannelSelectionRequired')
        end

        function testGetDataInUnitsWithDataPipeAndChannelConversion(testCase)
            % A DataPipe answers size() without loading, which is what the
            % channel count is taken from.
            channelConversion = testCase.ChannelConversion;
            numChannels = numel(channelConversion);
            electricalSeries = types.core.ElectricalSeries( ...
                'data', types.untyped.DataPipe('data', ones(numChannels, 6)), ...
                'data_conversion', 10, 'data_offset', 3, ...
                'channel_conversion', channelConversion);

            dataInUnits = electricalSeries.getDataInUnits();

            for iChannel = 1:numChannels
                testCase.verifyEqual(dataInUnits(iChannel, :), ...
                    ones(1, 6) * 10 * channelConversion(iChannel) + 3)
            end
        end

        function testApplyConversionWithScalarChannelConversion(testCase)
            % A single channel conversion factor applies to every channel,
            % so a subset needs no channel selection.
            electricalSeries = types.core.ElectricalSeries( ...
                'data', ones(5, 10), ...
                'data_conversion', 2, ...
                'channel_conversion', 4);

            testCase.verifyEqual( ...
                electricalSeries.applyConversion(electricalSeries.data(3:5, :)), ...
                ones(3, 10) * 8)
        end

        function testApplyConversionIgnoresChannelsWithoutChannelConversion(testCase)
            % A plain TimeSeries scales every channel the same way, so a
            % channel selection makes no difference to the result.
            timeSeries = types.core.TimeSeries( ...
                'data', ones(5, 10), 'data_unit', 'volts', 'data_conversion', 2);

            testCase.verifyEqual( ...
                timeSeries.applyConversion(timeSeries.data(3:5, :), 'Channels', 3:5), ...
                ones(3, 10) * 2)
        end

        function testApplyConversionWithNonNumericData(testCase)
            annotationSeries = types.core.AnnotationSeries( ...
                'data', {'a'; 'b'; 'c'}, 'timestamps', [1; 2; 3]);

            testCase.verifyError( ...
                @() annotationSeries.applyConversion(annotationSeries.data), ...
                'NWB:TimeSeries:ApplyConversion:NonNumericData')
        end
    end

    methods (Access = private)
        function electricalSeries = createElectricalSeries(testCase)
        % createElectricalSeries - Series with a per-channel conversion
        %
        % The data increases along both dimensions so that a wrong channel
        % selection or a wrong channel dimension changes the result.

            numChannels = numel(testCase.ChannelConversion);
            numSamples = 8;
            data = reshape(1:(numChannels*numSamples), numChannels, numSamples);

            electricalSeries = types.core.ElectricalSeries( ...
                'data', data, ...
                'data_conversion', 10, ...
                'data_offset', 3, ...
                'channel_conversion', testCase.ChannelConversion);
        end
    end
end
