classdef (Abstract) TimeSeriesBase < handle
% TimeSeriesBase - Non-generated base class for TimeSeries behavior.
%
% This class owns handwritten TimeSeries behavior that the generated
% schema class cannot express. It provides getDataInUnits, which resolves
% the whole stored (raw) dataset into the unit of measurement named by the
% 'data_unit' property, and applyConversion, which does the same for data
% that has already been loaded.

    properties (Abstract)
        data
        data_conversion
        data_offset
    end

    methods
        function data = getDataInUnits(obj)
        % getDataInUnits - Get the data in the unit of measurement of this TimeSeries
        %
        % Syntax:
        %  data = timeSeries.getDataInUnits() returns the data of the
        %  TimeSeries scaled into the unit given by its 'data_unit'
        %  property, by applying the conversion factor and the offset:
        %
        %    data = rawData * data_conversion + data_offset
        %
        %  If the TimeSeries also defines a 'channel_conversion' (as
        %  ElectricalSeries does), the channel-specific conversion factor
        %  is applied to each channel in addition to the global conversion
        %  factor:
        %
        %    data(i,:) = rawData(i,:) * data_conversion * channel_conversion(i) + data_offset
        %
        % Output Arguments:
        %  - data (numeric) -
        %    Data expressed in the unit of measurement given by the
        %    'data_unit' property. The output is of type double, unless the
        %    stored data is single, in which case it is single.
        %
        % Note: This reads the whole dataset into memory. To scale a subset
        % of a large dataset, load the subset from the 'data' property and
        % pass it to applyConversion.
        %
        % See also types.core.TimeSeries, applyConversion

            arguments
                obj (1,1) matnwb.neurodata.TimeSeriesBase
            end

            rawData = resolveDatasetValue(obj.data, 'data');
            data = obj.applyConversion(rawData);
        end

        function data = applyConversion(obj, rawData, options)
        % applyConversion - Scale loaded data into the unit of measurement of this TimeSeries
        %
        % Syntax:
        %  data = timeSeries.applyConversion(rawData) scales rawData into
        %  the unit given by the 'data_unit' property, applying the same
        %  conversion factor and offset as getDataInUnits. Use it to scale
        %  a subset loaded from the 'data' property, which avoids reading
        %  the whole dataset into memory:
        %
        %    rawData = timeSeries.data(1:10, 1:1000);
        %    data = timeSeries.applyConversion(rawData);
        %
        %  data = timeSeries.applyConversion(rawData, 'Channels', channels)
        %  states which channels rawData holds. This is required when the
        %  TimeSeries defines a per-channel 'channel_conversion' (as
        %  ElectricalSeries does) and rawData covers only some of those
        %  channels, because the conversion factor differs per channel:
        %
        %    rawData = electricalSeries.data(3:5, 1:1000);
        %    data = electricalSeries.applyConversion(rawData, 'Channels', 3:5);
        %
        %  When rawData covers every channel, 'Channels' can be omitted.
        %
        % Input Arguments:
        %  - rawData (numeric | logical) -
        %    Stored values, as read from the 'data' property.
        %
        %  - Channels (numeric) -
        %    Indices of the channels held by rawData, in the order they
        %    appear along the channel dimension of rawData. Ignored unless
        %    the TimeSeries defines a per-channel 'channel_conversion',
        %    because the conversion is otherwise the same for every channel.
        %
        % Output Arguments:
        %  - data (numeric) -
        %    Data expressed in the unit of measurement given by the
        %    'data_unit' property. The output is of type double, unless
        %    rawData is single, in which case it is single.
        %
        % Note: The channel indices are not checked against the ones used to
        % load rawData, so a selection that does not match the load produces
        % silently mis-scaled data.
        %
        % See also types.core.TimeSeries, getDataInUnits

            arguments
                obj (1,1) matnwb.neurodata.TimeSeriesBase
                rawData
                options.Channels (1,:) double {mustBeInteger, mustBePositive, mustBeNonempty}
            end

            if ~(isnumeric(rawData) || islogical(rawData))
                error('NWB:TimeSeries:ApplyConversion:NonNumericData', ...
                    ['Can not apply a conversion to data of type "%s". ', ...
                    'Conversion is only supported for numeric data.'], ...
                    class(rawData))
            end

            % Integer arithmetic in MATLAB saturates and stays integral, so
            % the raw data has to be promoted to a floating point type
            % before the conversion factor is applied.
            if isa(rawData, 'single')
                workingType = 'single';
            else
                workingType = 'double';
            end

            scaleFactor = cast(resolveScalar(obj.data_conversion, 1), workingType);
            offset = cast(resolveScalar(obj.data_offset, 0), workingType);

            % 'channel_conversion' is declared by subclasses such as
            % ElectricalSeries, not by TimeSeries, so it has to be reached
            % through dynamic property access.
            if isprop(obj, 'channel_conversion') && ~isempty(obj.("channel_conversion"))
                channelConversion = resolveDatasetValue( ...
                    obj.("channel_conversion"), 'channel_conversion');
                scaleFactor = scaleFactor .* obj.resolveChannelConversion( ...
                    cast(channelConversion, workingType), rawData, options);
            end

            data = cast(rawData, workingType) .* scaleFactor + offset;
        end
    end

    methods (Access = private)
        function channelConversion = resolveChannelConversion(obj, channelConversion, rawData, options)
        % resolveChannelConversion - Select and orient the channel conversion factors
        %
        % Picks the factors belonging to the channels held by rawData and
        % reshapes them so they broadcast along its channel dimension.

            if isscalar(channelConversion)
                % A single factor broadcasts across the whole array, so
                % there is no channel dimension to resolve and no channel
                % selection to apply.
                return
            end

            channelDimension = obj.getChannelDimension(rawData);
            numLoadedChannels = size(rawData, channelDimension);
            numDefinedChannels = numel(channelConversion);

            if isfield(options, 'Channels')
                channelIndices = options.Channels;
                if numel(channelIndices) ~= numLoadedChannels
                    error('NWB:TimeSeries:ApplyConversion:InvalidChannelSelection', ...
                        ['"Channels" names %d channels, but dimension %d of data ', ...
                        'holds %d. Specify one channel index per channel in data.'], ...
                        numel(channelIndices), channelDimension, numLoadedChannels)
                end
                if max(channelIndices) > numDefinedChannels
                    error('NWB:TimeSeries:ApplyConversion:InvalidChannelSelection', ...
                        ['"Channels" refers to channel %d, but "channel_conversion" ', ...
                        'only defines %d channels. Specify indices into ', ...
                        '"channel_conversion".'], ...
                        max(channelIndices), numDefinedChannels)
                end
                channelConversion = channelConversion(channelIndices);
            elseif numLoadedChannels > numDefinedChannels
                error('NWB:TimeSeries:ApplyConversion:ChannelConversionMismatch', ...
                    ['Dimension %d of data holds %d channels, but ', ...
                    '"channel_conversion" only defines %d conversion factors. ', ...
                    'Store one conversion factor per channel.'], ...
                    channelDimension, numLoadedChannels, numDefinedChannels)
            elseif numLoadedChannels < numDefinedChannels
                error('NWB:TimeSeries:ApplyConversion:ChannelSelectionRequired', ...
                    ['Dimension %d of data holds %d of the %d channels defined by ', ...
                    '"channel_conversion". Name the channels it holds with the ', ...
                    '"Channels" argument, for example ', ...
                    'applyConversion(data, ''Channels'', 1:%d).'], ...
                    channelDimension, numLoadedChannels, numDefinedChannels, numLoadedChannels)
            end

            newShape = ones(1, max(2, ndims(rawData)));
            newShape(channelDimension) = numel(channelConversion);
            channelConversion = reshape(channelConversion, newShape);
        end

        function channelDimension = getChannelDimension(obj, rawData)
        % getChannelDimension - Find the dimension of the data holding channels
        %
        % The 'axis' attribute of channel_conversion is the zero-based axis
        % of the dataset as it is laid out in the file. MatNWB reverses the
        % dimension order when reading, so the corresponding MATLAB
        % dimension is counted from the end of the array instead.

            channelAxis = 1; % Fixed to 1 by the schema, but read it if available.
            if isprop(obj, 'channel_conversion_axis') ...
                    && ~isempty(obj.("channel_conversion_axis"))
                channelAxis = double(obj.("channel_conversion_axis"));
            end
            channelDimension = max(1, ndims(rawData) - channelAxis);
        end
    end
end

function value = resolveDatasetValue(value, propertyName)
% resolveDatasetValue - Read a dataset property fully into memory
    if isa(value, 'types.untyped.ExternalLink')
        value = value.deref();
    elseif isa(value, 'types.untyped.SoftLink')
        error('NWB:TimeSeries:UnresolvedSoftLink', ...
            ['The "%s" property is a SoftLink, which can not be resolved ', ...
            'without the NwbFile it belongs to. Dereference the link and ', ...
            'apply the conversion to the target dataset instead.'], propertyName)
    end

    if isa(value, 'types.untyped.DataStub') || isa(value, 'types.untyped.DataPipe')
        value = value.load();
    end
end

function value = resolveScalar(value, defaultValue)
% resolveScalar - Fall back to the schema default for an unset attribute
    if isempty(value)
        value = defaultValue;
    end
end
