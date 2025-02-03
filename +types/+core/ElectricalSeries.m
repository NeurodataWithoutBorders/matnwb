classdef ElectricalSeries < types.core.TimeSeries & types.untyped.GroupClass
% ELECTRICALSERIES - A time series of acquired voltage data from extracellular recordings. The data field is an int or float array storing data in volts. The first dimension should always represent time. The second dimension, if present, should represent channels.
%
% Required Properties:
%  data, electrodes


% READONLY PROPERTIES
properties(SetAccess = protected)
    channel_conversion_axis; %  (int32) The zero-indexed axis of the 'data' dataset that the channel-specific conversion factor corresponds to. This value is fixed to 1.
end
% REQUIRED PROPERTIES
properties
    electrodes; % REQUIRED (DynamicTableRegion) DynamicTableRegion pointer to the electrodes that this time series was generated from.
end
% OPTIONAL PROPERTIES
properties
    channel_conversion; %  (single) Channel-specific conversion factor. Multiply the data in the 'data' dataset by these values along the channel axis (as indicated by axis attribute) AND by the global conversion factor in the 'conversion' attribute of 'data' to get the data values in Volts, i.e, data in Volts = data * data.conversion * channel_conversion. This approach allows for both global and per-channel data conversion factors needed to support the storage of electrical recordings as native values generated by data acquisition systems. If this dataset is not present, then there is no channel-specific conversion factor, i.e. it is 1 for all channels.
    filtering; %  (char) Filtering applied to all channels of the data. For example, if this ElectricalSeries represents high-pass-filtered data (also known as AP Band), then this value could be "High-pass 4-pole Bessel filter at 500 Hz". If this ElectricalSeries represents low-pass-filtered LFP data and the type of filter is unknown, then this value could be "Low-pass filter at 300 Hz". If a non-standard filter type is used, provide as much detail about the filter properties as possible.
end

methods
    function obj = ElectricalSeries(varargin)
        % ELECTRICALSERIES - Constructor for ElectricalSeries
        %
        % Syntax:
        %  electricalSeries = types.core.ELECTRICALSERIES() creates a ElectricalSeries object with unset property values.
        %
        %  electricalSeries = types.core.ELECTRICALSERIES(Name, Value) creates a ElectricalSeries object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - channel_conversion (single) - Channel-specific conversion factor. Multiply the data in the 'data' dataset by these values along the channel axis (as indicated by axis attribute) AND by the global conversion factor in the 'conversion' attribute of 'data' to get the data values in Volts, i.e, data in Volts = data * data.conversion * channel_conversion. This approach allows for both global and per-channel data conversion factors needed to support the storage of electrical recordings as native values generated by data acquisition systems. If this dataset is not present, then there is no channel-specific conversion factor, i.e. it is 1 for all channels.
        %
        %  - comments (char) - Human-readable comments about the TimeSeries. This second descriptive field can be used to store additional information, or descriptive information if the primary description field is populated with a computer-readable string.
        %
        %  - control (uint8) - Numerical labels that apply to each time point in data for the purpose of querying and slicing data by these values. If present, the length of this array should be the same size as the first dimension of data.
        %
        %  - control_description (char) - Description of each control value. Must be present if control is present. If present, control_description[0] should describe time points where control == 0.
        %
        %  - data (numeric) - Recorded voltage data.
        %
        %  - data_continuity (char) - Optionally describe the continuity of the data. Can be "continuous", "instantaneous", or "step". For example, a voltage trace would be "continuous", because samples are recorded from a continuous process. An array of lick times would be "instantaneous", because the data represents distinct moments in time. Times of image presentations would be "step" because the picture remains the same until the next timepoint. This field is optional, but is useful in providing information about the underlying data. It may inform the way this data is interpreted, the way it is visualized, and what analysis methods are applicable.
        %
        %  - data_conversion (single) - Scalar to multiply each element in data to convert it to the specified 'unit'. If the data are stored in acquisition system units or other units that require a conversion to be interpretable, multiply the data by 'conversion' to convert the data to the specified 'unit'. e.g. if the data acquisition system stores values in this object as signed 16-bit integers (int16 range -32,768 to 32,767) that correspond to a 5V range (-2.5V to 2.5V), and the data acquisition system gain is 8000X, then the 'conversion' multiplier to get from raw data acquisition values to recorded volts is 2.5/32768/8000 = 9.5367e-9.
        %
        %  - data_offset (single) - Scalar to add to the data after scaling by 'conversion' to finalize its coercion to the specified 'unit'. Two common examples of this include (a) data stored in an unsigned type that requires a shift after scaling to re-center the data, and (b) specialized recording devices that naturally cause a scalar offset with respect to the true units.
        %
        %  - data_resolution (single) - Smallest meaningful difference between values in data, stored in the specified by unit, e.g., the change in value of the least significant bit, or a larger number if signal noise is known to be present. If unknown, use -1.0.
        %
        %  - description (char) - Description of the time series.
        %
        %  - electrodes (DynamicTableRegion) - DynamicTableRegion pointer to the electrodes that this time series was generated from.
        %
        %  - filtering (char) - Filtering applied to all channels of the data. For example, if this ElectricalSeries represents high-pass-filtered data (also known as AP Band), then this value could be "High-pass 4-pole Bessel filter at 500 Hz". If this ElectricalSeries represents low-pass-filtered LFP data and the type of filter is unknown, then this value could be "Low-pass filter at 300 Hz". If a non-standard filter type is used, provide as much detail about the filter properties as possible.
        %
        %  - starting_time (double) - Timestamp of the first sample in seconds. When timestamps are uniformly spaced, the timestamp of the first sample can be specified and all subsequent ones calculated from the sampling rate attribute.
        %
        %  - starting_time_rate (single) - Sampling rate, in Hz.
        %
        %  - timestamps (double) - Timestamps for samples stored in data, in seconds, relative to the common experiment master-clock stored in NWBFile.timestamps_reference_time.
        %
        % Output Arguments:
        %  - electricalSeries (types.core.ElectricalSeries) - A ElectricalSeries object
        
        varargin = [{'channel_conversion_axis' types.util.correctType(1, 'int32') 'data_unit' 'volts'} varargin];
        obj = obj@types.core.TimeSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'channel_conversion',[]);
        addParameter(p, 'channel_conversion_axis',[]);
        addParameter(p, 'data',[]);
        addParameter(p, 'data_unit',[]);
        addParameter(p, 'electrodes',[]);
        addParameter(p, 'filtering',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.channel_conversion = p.Results.channel_conversion;
        obj.channel_conversion_axis = p.Results.channel_conversion_axis;
        obj.data = p.Results.data;
        obj.data_unit = p.Results.data_unit;
        obj.electrodes = p.Results.electrodes;
        obj.filtering = p.Results.filtering;
        if strcmp(class(obj), 'types.core.ElectricalSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.channel_conversion(obj, val)
        obj.channel_conversion = obj.validate_channel_conversion(val);
    end
    function set.electrodes(obj, val)
        obj.electrodes = obj.validate_electrodes(val);
    end
    function set.filtering(obj, val)
        obj.filtering = obj.validate_filtering(val);
    end
    %% VALIDATORS
    
    function val = validate_channel_conversion(obj, val)
        val = types.util.checkDtype('channel_conversion', 'single', val);
        if isa(val, 'types.untyped.DataStub')
            if 1 == val.ndims
                valsz = [val.dims 1];
            else
                valsz = val.dims;
            end
        elseif istable(val)
            valsz = [height(val) 1];
        elseif ischar(val)
            valsz = [size(val, 1) 1];
        else
            valsz = size(val);
        end
        validshapes = {[Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'numeric', val);
        if isa(val, 'types.untyped.DataStub')
            if 1 == val.ndims
                valsz = [val.dims 1];
            else
                valsz = val.dims;
            end
        elseif istable(val)
            valsz = [height(val) 1];
        elseif ischar(val)
            valsz = [size(val, 1) 1];
        else
            valsz = size(val);
        end
        validshapes = {[Inf,Inf,Inf], [Inf,Inf], [Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_data_unit(obj, val)
        if isequal(val, 'volts')
            val = 'volts';
        else
            error('NWB:Type:ReadOnlyProperty', 'Unable to set the ''data_unit'' property of class ''<a href="matlab:doc types.core.ElectricalSeries">ElectricalSeries</a>'' because it is read-only.')
        end
    end
    function val = validate_electrodes(obj, val)
        val = types.util.checkDtype('electrodes', 'types.hdmf_common.DynamicTableRegion', val);
    end
    function val = validate_filtering(obj, val)
        val = types.util.checkDtype('filtering', 'char', val);
        if isa(val, 'types.untyped.DataStub')
            if 1 == val.ndims
                valsz = [val.dims 1];
            else
                valsz = val.dims;
            end
        elseif istable(val)
            valsz = [height(val) 1];
        elseif ischar(val)
            valsz = [size(val, 1) 1];
        else
            valsz = size(val);
        end
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.TimeSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.channel_conversion)
            if startsWith(class(obj.channel_conversion), 'types.untyped.')
                refs = obj.channel_conversion.export(fid, [fullpath '/channel_conversion'], refs);
            elseif ~isempty(obj.channel_conversion)
                io.writeDataset(fid, [fullpath '/channel_conversion'], obj.channel_conversion, 'forceArray');
            end
        end
        if ~isempty(obj.channel_conversion) && ~isa(obj.channel_conversion, 'types.untyped.SoftLink') && ~isa(obj.channel_conversion, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/channel_conversion/axis'], obj.channel_conversion_axis);
        end
        if ~isempty(obj.channel_conversion) && isempty(obj.channel_conversion_axis)
            obj.warnIfRequiredDependencyMissing('channel_conversion_axis', 'channel_conversion', fullpath)
        end
        refs = obj.electrodes.export(fid, [fullpath '/electrodes'], refs);
        if ~isempty(obj.filtering)
            io.writeAttribute(fid, [fullpath '/filtering'], obj.filtering);
        end
    end
end

end