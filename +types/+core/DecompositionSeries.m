classdef DecompositionSeries < types.core.TimeSeries & types.untyped.GroupClass
% DECOMPOSITIONSERIES - Spectral analysis of a time series, e.g. of an LFP or a speech signal.
%
% Required Properties:
%  data, data_unit, metric


% REQUIRED PROPERTIES
properties
    metric; % REQUIRED (char) The metric used, e.g. phase, amplitude, power.
end
% OPTIONAL PROPERTIES
properties
    bands; %  (FrequencyBandsTable) Table for describing the bands that this series was generated from.
    source_channels; %  (DynamicTableRegion) DynamicTableRegion pointer to the channels that this decomposition series was generated from.
    source_timeseries; %  TimeSeries
end

methods
    function obj = DecompositionSeries(varargin)
        % DECOMPOSITIONSERIES - Constructor for DecompositionSeries
        %
        % Syntax:
        %  decompositionSeries = types.core.DECOMPOSITIONSERIES() creates a DecompositionSeries object with unset property values.
        %
        %  decompositionSeries = types.core.DECOMPOSITIONSERIES(Name, Value) creates a DecompositionSeries object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - bands (FrequencyBandsTable) - Table for describing the bands that this series was generated from.
        %
        %  - comments (char) - Human-readable comments about the TimeSeries. This second descriptive field can be used to store additional information, or descriptive information if the primary description field is populated with a computer-readable string.
        %
        %  - control (uint8) - Numerical labels that apply to each time point in data for the purpose of querying and slicing data by these values. If present, the length of this array should be the same size as the first dimension of data.
        %
        %  - control_description (char) - Description of each control value. Must be present if control is present. If present, control_description[0] should describe time points where control == 0.
        %
        %  - data (numeric) - Data decomposed into frequency bands.
        %
        %  - data_continuity (char) - Optionally describe the continuity of the data. Can be "continuous", "instantaneous", or "step". For example, a voltage trace would be "continuous", because samples are recorded from a continuous process. An array of lick times would be "instantaneous", because the data represents distinct moments in time. Times of image presentations would be "step" because the picture remains the same until the next timepoint. This field is optional, but is useful in providing information about the underlying data. It may inform the way this data is interpreted, the way it is visualized, and what analysis methods are applicable.
        %
        %  - data_conversion (single) - Scalar to multiply each element in data to convert it to the specified 'unit'. If the data are stored in acquisition system units or other units that require a conversion to be interpretable, multiply the data by 'conversion' to convert the data to the specified 'unit'. e.g. if the data acquisition system stores values in this object as signed 16-bit integers (int16 range -32,768 to 32,767) that correspond to a 5V range (-2.5V to 2.5V), and the data acquisition system gain is 8000X, then the 'conversion' multiplier to get from raw data acquisition values to recorded volts is 2.5/32768/8000 = 9.5367e-9.
        %
        %  - data_offset (single) - Scalar to add to the data after scaling by 'conversion' to finalize its coercion to the specified 'unit'. Two common examples of this include (a) data stored in an unsigned type that requires a shift after scaling to re-center the data, and (b) specialized recording devices that naturally cause a scalar offset with respect to the true units.
        %
        %  - data_resolution (single) - Smallest meaningful difference between values in data, stored in the specified by unit, e.g., the change in value of the least significant bit, or a larger number if signal noise is known to be present. If unknown, use -1.0.
        %
        %  - data_unit (char) - Base unit of measurement for working with the data. Actual stored values are not necessarily stored in these units. To access the data in these units, multiply 'data' by 'conversion'.
        %
        %  - description (char) - Description of the time series.
        %
        %  - metric (char) - The metric used, e.g. phase, amplitude, power.
        %
        %  - source_channels (DynamicTableRegion) - DynamicTableRegion pointer to the channels that this decomposition series was generated from.
        %
        %  - source_timeseries (TimeSeries) - Link to TimeSeries object that this data was calculated from. Metadata about electrodes and their position can be read from that ElectricalSeries so it is not necessary to store that information here.
        %
        %  - starting_time (double) - Timestamp of the first sample in seconds. When timestamps are uniformly spaced, the timestamp of the first sample can be specified and all subsequent ones calculated from the sampling rate attribute.
        %
        %  - starting_time_rate (single) - Sampling rate, in Hz.
        %
        %  - timestamps (double) - Timestamps for samples stored in data, in seconds, relative to the common experiment master-clock stored in NWBFile.timestamps_reference_time.
        %
        % Output Arguments:
        %  - decompositionSeries (types.core.DecompositionSeries) - A DecompositionSeries object
        
        varargin = [{'data_unit' 'no unit'} varargin];
        obj = obj@types.core.TimeSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'bands',[]);
        addParameter(p, 'metric',[]);
        addParameter(p, 'source_channels',[]);
        addParameter(p, 'source_timeseries',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.bands = p.Results.bands;
        obj.metric = p.Results.metric;
        obj.source_channels = p.Results.source_channels;
        obj.source_timeseries = p.Results.source_timeseries;
        if strcmp(class(obj), 'types.core.DecompositionSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.bands(obj, val)
        obj.bands = obj.validate_bands(val);
    end
    function set.metric(obj, val)
        obj.metric = obj.validate_metric(val);
    end
    function set.source_channels(obj, val)
        obj.source_channels = obj.validate_source_channels(val);
    end
    function set.source_timeseries(obj, val)
        obj.source_timeseries = obj.validate_source_timeseries(val);
    end
    %% VALIDATORS
    
    function val = validate_bands(obj, val)
        val = types.util.checkDtype('bands', 'types.core.FrequencyBandsTable', val);
    end
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'numeric', val);
        types.util.validateShape('data', {[Inf,Inf,Inf]}, val)
    end
    function val = validate_data_unit(obj, val)
        val = types.util.checkDtype('data_unit', 'char', val);
        types.util.validateShape('data_unit', {[1]}, val)
    end
    function val = validate_metric(obj, val)
        val = types.util.checkDtype('metric', 'char', val);
        types.util.validateShape('metric', {[1]}, val)
    end
    function val = validate_source_channels(obj, val)
        val = types.util.checkDtype('source_channels', 'types.hdmf_common.DynamicTableRegion', val);
    end
    function val = validate_source_timeseries(obj, val)
        if isa(val, 'types.untyped.SoftLink')
            if isprop(val, 'target')
                types.util.checkDtype('source_timeseries', 'types.core.TimeSeries', val.target);
            end
        else
            val = types.util.checkDtype('source_timeseries', 'types.core.TimeSeries', val);
            if ~isempty(val)
                val = types.untyped.SoftLink(val);
            end
        end
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.TimeSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.bands)
            refs = obj.bands.export(fid, [fullpath '/bands'], refs);
        end
        if startsWith(class(obj.metric), 'types.untyped.')
            refs = obj.metric.export(fid, [fullpath '/metric'], refs);
        elseif ~isempty(obj.metric)
            io.writeDataset(fid, [fullpath '/metric'], obj.metric);
        end
        if ~isempty(obj.source_channels)
            refs = obj.source_channels.export(fid, [fullpath '/source_channels'], refs);
        end
        if ~isempty(obj.source_timeseries)
            refs = obj.source_timeseries.export(fid, [fullpath '/source_timeseries'], refs);
        end
    end
end

end