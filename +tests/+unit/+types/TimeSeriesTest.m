classdef TimeSeriesTest < tests.abstract.NwbTestCase
% TimeSeriesTest - Unit tests for handwritten TimeSeries behavior.

    properties (Constant, Access = private)
        % Every factor is exactly representable as single, the type
        % channel_conversion is stored as, so the expected values in the
        % tests below are exact.
        ChannelConversion = [0.5; 0.25; 0.125; 2; 4]
        Conversion = 10
        Offset = 3
    end

    methods (TestClassSetup)
        function setupTemporaryWorkingFolder(testCase)
            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testGetDataInUnitsAppliesConversionAndOffset(testCase)
            % An unmodified TimeSeries uses conversion 1 and offset 0, so
            % the data is returned unchanged.
            timeSeries = types.core.TimeSeries( ...
                'data', [1; 2; 3], 'data_unit', 'volts');
            testCase.verifyEqual(timeSeries.getDataInUnits(), [1; 2; 3])

            timeSeries = types.core.TimeSeries( ...
                'data', [1; 2; 3], 'data_unit', 'volts', ...
                'data_conversion', 2, 'data_offset', 3);
            testCase.verifyEqual(timeSeries.getDataInUnits(), [5; 7; 9])
        end

        function testGetDataInUnitsPromotesIntegerData(testCase)
            % Integer arithmetic in MATLAB rounds and saturates, so the raw
            % data must be promoted to a floating point type before the
            % conversion factor is applied. Both values would saturate at
            % the limits of int16 otherwise.
            timeSeries = types.core.TimeSeries( ...
                'data', int16([30000; -30000]), 'data_unit', 'volts', ...
                'data_conversion', 2.5);

            dataInUnits = timeSeries.getDataInUnits();

            testCase.verifyClass(dataInUnits, 'double')
            testCase.verifyEqual(dataInUnits, [75000; -75000])
        end

        function testGetDataInUnitsPreservesSingleData(testCase)
            timeSeries = types.core.TimeSeries( ...
                'data', single([1; 2; 3]), 'data_unit', 'volts', ...
                'data_conversion', 2);

            dataInUnits = timeSeries.getDataInUnits();

            testCase.verifyClass(dataInUnits, 'single')
            testCase.verifyEqual(dataInUnits, single([2; 4; 6]))
        end

        function testGetDataInUnitsWithChannelConversion(testCase)
            % In MatNWB the dimensions of a dataset are reversed relative
            % to the file, so an ElectricalSeries holds channels along the
            % first dimension and the channel conversion applies to rows.
            electricalSeries = testCase.createElectricalSeries();

            dataInUnits = electricalSeries.getDataInUnits();

            testCase.verifyEqual(dataInUnits, testCase.expectedDataInUnits( ...
                electricalSeries.data, testCase.ChannelConversion))
        end

        function testGetDataInUnitsWithThreeDimensionalData(testCase)
            % ElectricalSeries data can be [samples x channels x time] in
            % MatNWB, which puts the channels along the second dimension
            % and so exercises the reshaping of the conversion factors.
            electricalSeries = testCase.createElectricalSeries3D();

            dataInUnits = electricalSeries.getDataInUnits();

            testCase.verifyEqual(dataInUnits, testCase.expectedDataInUnits( ...
                electricalSeries.data, reshape(testCase.ChannelConversion, 1, [])))
        end

        function testGetDataInUnitsWithDataPipe(testCase)
            % A DataPipe answers size() without loading, which is what the
            % channel count is taken from.
            electricalSeries = types.core.ElectricalSeries( ...
                'data', types.untyped.DataPipe('data', ones(5, 6)), ...
                'data_conversion', 2, ...
                'channel_conversion', [1; 2; 3; 4; 5]);

            testCase.verifyEqual( ...
                electricalSeries.getDataInUnits(), repmat((2:2:10)', 1, 6))
        end

        function testConversionWithScalarChannelConversion(testCase)
            % A single channel conversion factor applies to every channel,
            % so it needs no channel dimension and a subset needs no
            % channel selection.
            electricalSeries = types.core.ElectricalSeries( ...
                'data', ones(5, 10), ...
                'data_conversion', 2, ...
                'channel_conversion', 4);

            testCase.verifyEqual( ...
                electricalSeries.getDataInUnits(), ones(5, 10) * 8)
            testCase.verifyEqual( ...
                electricalSeries.applyConversion(electricalSeries.data(3:5, :)), ...
                ones(3, 10) * 8)
        end

        function testConversionWithMismatchedChannelConversion(testCase)
            % The channel count is taken from the data of the TimeSeries,
            % so a subset cannot hide a channel_conversion of the wrong
            % length: neither one that happens to match the subset's size
            % nor one that would otherwise look like a partial load.
            electricalSeries = types.core.ElectricalSeries( ...
                'data', ones(5, 10), 'channel_conversion', ones(4, 1));
            expectedError = 'NWB:TimeSeries:ApplyConversion:ChannelConversionMismatch';

            testCase.verifyError( ...
                @() electricalSeries.getDataInUnits(), expectedError)
            testCase.verifyError( ...
                @() electricalSeries.applyConversion(electricalSeries.data(1:4, :)), ...
                expectedError)
            testCase.verifyError( ...
                @() electricalSeries.applyConversion(electricalSeries.data(1:3, :)), ...
                expectedError)
        end

        function testConversionWithNonNumericData(testCase)
            annotationSeries = types.core.AnnotationSeries( ...
                'data', {'a'; 'b'; 'c'}, 'timestamps', [1; 2; 3]);
            expectedError = 'NWB:TimeSeries:ApplyConversion:NonNumericData';

            testCase.verifyError( ...
                @() annotationSeries.getDataInUnits(), expectedError)
            testCase.verifyError( ...
                @() annotationSeries.applyConversion(annotationSeries.data), ...
                expectedError)
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

        function testApplyConversionWithChannelSelection(testCase)
            % The conversion factors follow the order of the channels in
            % the data, not their order in channel_conversion. Channel
            % indices are often produced by find, which returns a column,
            % so that orientation is accepted too.
            electricalSeries = testCase.createElectricalSeries();
            dataInUnits = electricalSeries.getDataInUnits();

            selectedChannels = [5; 1; 3];
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

        function testApplyConversionRejectsInvalidChannelSelection(testCase)
            electricalSeries = testCase.createElectricalSeries();
            subset = electricalSeries.data(3:5, :);
            expectedError = 'NWB:TimeSeries:ApplyConversion:InvalidChannelSelection';

            % Wrong number of channels.
            testCase.verifyError( ...
                @() electricalSeries.applyConversion(subset, 'Channels', 3:4), ...
                expectedError)
            % Channel index beyond the channels of the TimeSeries.
            testCase.verifyError( ...
                @() electricalSeries.applyConversion(subset, 'Channels', 4:6), ...
                expectedError)
        end

        function testApplyConversionWithDataFromAnotherTimeSeries(testCase)
            % More channels than the TimeSeries has cannot be a subset of
            % its data, so it is reported rather than scaled.
            electricalSeries = testCase.createElectricalSeries();

            testCase.verifyError( ...
                @() electricalSeries.applyConversion(ones(7, 3)), ...
                'NWB:TimeSeries:ApplyConversion:DataMismatch')
        end

        function testApplyConversionOnTimeSliceOfThreeDimensionalData(testCase)
            % A time slice of [samples x channels x time] data comes back
            % two-dimensional, because MATLAB drops trailing singleton
            % dimensions. The channels still lie along the second
            % dimension, which has to be found from the rank of the stored
            % data rather than from the rank of the slice.
            electricalSeries = testCase.createElectricalSeries3D();
            dataInUnits = electricalSeries.getDataInUnits();

            timeSlice = electricalSeries.data(:, :, 2);
            testCase.assertSize(timeSlice, [4, numel(testCase.ChannelConversion)])

            testCase.verifyEqual( ...
                electricalSeries.applyConversion(timeSlice), ...
                dataInUnits(:, :, 2))

            selectedChannels = [4 2];
            testCase.verifyEqual( ...
                electricalSeries.applyConversion( ...
                    timeSlice(:, selectedChannels), 'Channels', selectedChannels), ...
                dataInUnits(:, selectedChannels, 2))
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

        function testConversionOnReadFile(testCase)
            % After a round trip the data and the channel_conversion are
            % both DataStubs. getDataInUnits has to load the data, and
            % applyConversion has to take the channel count from the dims
            % of the data stub without loading it.
            numChannels = numel(testCase.ChannelConversion);
            nwbFile = tests.factory.NWBFile();
            nwbFile.acquisition.set('ElectricalSeries', types.core.ElectricalSeries( ...
                'data', int16(reshape(1:numChannels*7, numChannels, 7)), ...
                'electrodes', testCase.createElectrodeRegion(nwbFile, numChannels), ...
                'data_conversion', testCase.Conversion, ...
                'data_offset', testCase.Offset, ...
                'channel_conversion', testCase.ChannelConversion, ...
                'starting_time', 0, 'starting_time_rate', 1));

            nwbFilePath = testCase.getRandomFilename();
            nwbExport(nwbFile, nwbFilePath)
            electricalSeries = nwbRead(nwbFilePath, 'ignorecache').acquisition.get('ElectricalSeries');
            testCase.assertClass(electricalSeries.data, 'types.untyped.DataStub')

            dataInUnits = electricalSeries.getDataInUnits();
            testCase.verifyEqual(dataInUnits, testCase.expectedDataInUnits( ...
                electricalSeries.data.load(), testCase.ChannelConversion))

            selectedChannels = 2:4;
            subsetInUnits = electricalSeries.applyConversion( ...
                electricalSeries.data(selectedChannels, :), ...
                'Channels', selectedChannels);
            testCase.verifyEqual(subsetInUnits, dataInUnits(selectedChannels, :))

            testCase.verifyError( ...
                @() electricalSeries.applyConversion(electricalSeries.data(selectedChannels, :)), ...
                'NWB:TimeSeries:ApplyConversion:ChannelSelectionRequired')
        end
    end

    methods (Access = private)
        function electricalSeries = createElectricalSeries(testCase)
        % createElectricalSeries - [channels x samples] series with per-channel conversion
        %
        % The data increases along both dimensions so that a wrong channel
        % selection or a wrong channel dimension changes the result.

            numChannels = numel(testCase.ChannelConversion);
            numSamples = 8;
            data = reshape(1:(numChannels*numSamples), numChannels, numSamples);

            electricalSeries = types.core.ElectricalSeries( ...
                'data', data, ...
                'data_conversion', testCase.Conversion, ...
                'data_offset', testCase.Offset, ...
                'channel_conversion', testCase.ChannelConversion);
        end

        function electricalSeries = createElectricalSeries3D(testCase)
        % createElectricalSeries3D - [samples x channels x time] series with per-channel conversion

            numChannels = numel(testCase.ChannelConversion);
            numSamples = 4;
            numTimes = 6;
            data = reshape(1:(numSamples*numChannels*numTimes), ...
                numSamples, numChannels, numTimes);

            electricalSeries = types.core.ElectricalSeries( ...
                'data', data, ...
                'data_conversion', testCase.Conversion, ...
                'data_offset', testCase.Offset, ...
                'channel_conversion', testCase.ChannelConversion);
        end

        function expected = expectedDataInUnits(testCase, rawData, channelConversion)
        % expectedDataInUnits - Reference conversion, with the factors already oriented
        %
        % channelConversion must be shaped so that it expands along the
        % channel dimension of rawData: a column for [channels x samples]
        % data, a row for [samples x channels x time] data.

            expected = double(rawData) .* testCase.Conversion .* channelConversion ...
                + testCase.Offset;
        end
    end

    methods (Static, Access = private)
        function electrodes = createElectrodeRegion(nwbFile, numChannels)
        % createElectrodeRegion - Electrode table region covering numChannels electrodes

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
        end
    end
end
