classdef (Abstract) TimeSeriesBase < handle
% TimeSeriesBase - Non-generated base class for TimeSeries behavior.
%
% This class owns handwritten TimeSeries behavior that the generated
% schema class cannot express. It provides getDataInUnits, which resolves
% the stored (raw) data into the unit of measurement named by the
% 'data_unit' property.

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
        % of a large dataset, index the 'data' property directly and apply
        % the conversion and offset yourself.
        %
        % See also types.core.TimeSeries

            arguments
                obj (1,1) matnwb.neurodata.TimeSeriesBase
            end

            rawData = resolveDatasetValue(obj.data, 'data');

            if ~(isnumeric(rawData) || islogical(rawData))
                error('NWB:TimeSeries:GetDataInUnits:NonNumericData', ...
                    ['Can not apply a conversion to data of type "%s". ', ...
                    'getDataInUnits is only supported for numeric data.'], ...
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
                scaleFactor = scaleFactor .* obj.reshapeChannelConversion( ...
                    cast(channelConversion, workingType), rawData);
            end

            data = cast(rawData, workingType) .* scaleFactor + offset;
        end
    end

    methods (Access = private)
        function channelConversion = reshapeChannelConversion(obj, channelConversion, rawData)
        % reshapeChannelConversion - Orient channel conversion along the channel dimension
        %
        % The 'axis' attribute of channel_conversion is the zero-based axis
        % of the dataset as it is laid out in the file. MatNWB reverses the
        % dimension order when reading, so the corresponding MATLAB
        % dimension is counted from the end of the array instead.

            if isscalar(channelConversion)
                % A single factor broadcasts across the whole array, so
                % there is no channel dimension to resolve.
                return
            end

            channelAxis = 1; % Fixed to 1 by the schema, but read it if available.
            if isprop(obj, 'channel_conversion_axis') ...
                    && ~isempty(obj.("channel_conversion_axis"))
                channelAxis = double(obj.("channel_conversion_axis"));
            end
            channelDimension = max(1, ndims(rawData) - channelAxis);

            numChannels = numel(channelConversion);
            if size(rawData, channelDimension) ~= numChannels
                error('NWB:TimeSeries:GetDataInUnits:ChannelConversionMismatch', ...
                    ['The number of channel conversion factors (%d) does not ', ...
                    'match the length of dimension %d of data (%d).'], ...
                    numChannels, channelDimension, size(rawData, channelDimension))
            end

            newShape = ones(1, max(2, ndims(rawData)));
            newShape(channelDimension) = numChannels;
            channelConversion = reshape(channelConversion, newShape);
        end
    end
end

function value = resolveDatasetValue(value, propertyName)
% resolveDatasetValue - Read a dataset property fully into memory
    if isa(value, 'types.untyped.ExternalLink')
        value = value.deref();
    elseif isa(value, 'types.untyped.SoftLink')
        error('NWB:TimeSeries:GetDataInUnits:UnresolvedSoftLink', ...
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
