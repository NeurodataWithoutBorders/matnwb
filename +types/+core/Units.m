classdef Units < types.hdmf_common.DynamicTable & types.untyped.GroupClass
% UNITS - Data about spiking units. Event times of observed units (e.g. cell, synapse, etc.) should be concatenated and stored in spike_times.
%
% Required Properties:
%  colnames, description, id


% READONLY PROPERTIES
properties(SetAccess = protected)
    waveform_mean_unit = "volts"; %  (char) Unit of measurement. This value is fixed to 'volts'.
    waveform_sd_unit = "volts"; %  (char) Unit of measurement. This value is fixed to 'volts'.
    waveforms_unit = "volts"; %  (char) Unit of measurement. This value is fixed to 'volts'.
end
% OPTIONAL PROPERTIES
properties
    electrode_group; %  (VectorData) Electrode group that each spike unit came from.
    electrodes; %  (DynamicTableRegion) Electrode that each spike unit came from, specified using a DynamicTableRegion.
    electrodes_index; %  (VectorIndex) Index into electrodes.
    obs_intervals; %  (VectorData) Observation intervals for each unit.
    obs_intervals_index; %  (VectorIndex) Index into the obs_intervals dataset.
    spike_times; %  (VectorData) Spike times for each unit in seconds.
    spike_times_index; %  (VectorIndex) Index into the spike_times dataset.
    spike_times_resolution; %  (double) The smallest possible difference between two spike times. Usually 1 divided by the acquisition sampling rate from which spike times were extracted, but could be larger if the acquisition time series was downsampled or smaller if the acquisition time series was smoothed/interpolated and it is possible for the spike time to be between samples.
    waveform_mean; %  (VectorData) Spike waveform mean for each spike unit.
    waveform_mean_sampling_rate; %  (single) Sampling rate, in hertz.
    waveform_sd; %  (VectorData) Spike waveform standard deviation for each spike unit.
    waveform_sd_sampling_rate; %  (single) Sampling rate, in hertz.
    waveforms; %  (VectorData) Individual waveforms for each spike on each electrode. This is a doubly indexed column. The 'waveforms_index' column indexes which waveforms in this column belong to the same spike event for a given unit, where each waveform was recorded from a different electrode. The 'waveforms_index_index' column indexes the 'waveforms_index' column to indicate which spike events belong to a given unit. For example, if the 'waveforms_index_index' column has values [2, 5, 6], then the first 2 elements of the 'waveforms_index' column correspond to the 2 spike events of the first unit, the next 3 elements of the 'waveforms_index' column correspond to the 3 spike events of the second unit, and the next 1 element of the 'waveforms_index' column corresponds to the 1 spike event of the third unit. If the 'waveforms_index' column has values [3, 6, 8, 10, 12, 13], then the first 3 elements of the 'waveforms' column contain the 3 spike waveforms that were recorded from 3 different electrodes for the first spike time of the first unit. See https://nwb-schema.readthedocs.io/en/stable/format_description.html#doubly-ragged-arrays for a graphical representation of this example. When there is only one electrode for each unit (i.e., each spike time is associated with a single waveform), then the 'waveforms_index' column will have values 1, 2, ..., N, where N is the number of spike events. The number of electrodes for each spike event should be the same within a given unit. The 'electrodes' column should be used to indicate which electrodes are associated with each unit, and the order of the waveforms within a given unit x spike event should be the same as the order of the electrodes referenced in the 'electrodes' column of this table. The number of samples for each waveform must be the same.
    waveforms_index; %  (VectorIndex) Index into the 'waveforms' dataset. One value for every spike event. See 'waveforms' for more detail.
    waveforms_index_index; %  (VectorIndex) Index into the 'waveforms_index' dataset. One value for every unit (row in the table). See 'waveforms' for more detail.
    waveforms_sampling_rate; %  (single) Sampling rate, in hertz.
end

methods
    function obj = Units(varargin)
        % UNITS - Constructor for Units
        %
        % Syntax:
        %  units = types.core.UNITS() creates a Units object with unset property values.
        %
        %  units = types.core.UNITS(Name, Value) creates a Units object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - colnames (char) - The names of the columns in this table. This should be used to specify an order to the columns.
        %
        %  - description (char) - Description of what is in this dynamic table.
        %
        %  - electrode_group (VectorData) - Electrode group that each spike unit came from.
        %
        %  - electrodes (DynamicTableRegion) - Electrode that each spike unit came from, specified using a DynamicTableRegion.
        %
        %  - electrodes_index (VectorIndex) - Index into electrodes.
        %
        %  - id (ElementIdentifiers) - Array of unique identifiers for the rows of this dynamic table.
        %
        %  - obs_intervals (VectorData) - Observation intervals for each unit.
        %
        %  - obs_intervals_index (VectorIndex) - Index into the obs_intervals dataset.
        %
        %  - spike_times (VectorData) - Spike times for each unit in seconds.
        %
        %  - spike_times_index (VectorIndex) - Index into the spike_times dataset.
        %
        %  - spike_times_resolution (double) - The smallest possible difference between two spike times. Usually 1 divided by the acquisition sampling rate from which spike times were extracted, but could be larger if the acquisition time series was downsampled or smaller if the acquisition time series was smoothed/interpolated and it is possible for the spike time to be between samples.
        %
        %  - vectordata (VectorData) - Vector columns, including index columns, of this dynamic table.
        %
        %  - waveform_mean (VectorData) - Spike waveform mean for each spike unit.
        %
        %  - waveform_mean_sampling_rate (single) - Sampling rate, in hertz.
        %
        %  - waveform_sd (VectorData) - Spike waveform standard deviation for each spike unit.
        %
        %  - waveform_sd_sampling_rate (single) - Sampling rate, in hertz.
        %
        %  - waveforms (VectorData) - Individual waveforms for each spike on each electrode. This is a doubly indexed column. The 'waveforms_index' column indexes which waveforms in this column belong to the same spike event for a given unit, where each waveform was recorded from a different electrode. The 'waveforms_index_index' column indexes the 'waveforms_index' column to indicate which spike events belong to a given unit. For example, if the 'waveforms_index_index' column has values [2, 5, 6], then the first 2 elements of the 'waveforms_index' column correspond to the 2 spike events of the first unit, the next 3 elements of the 'waveforms_index' column correspond to the 3 spike events of the second unit, and the next 1 element of the 'waveforms_index' column corresponds to the 1 spike event of the third unit. If the 'waveforms_index' column has values [3, 6, 8, 10, 12, 13], then the first 3 elements of the 'waveforms' column contain the 3 spike waveforms that were recorded from 3 different electrodes for the first spike time of the first unit. See https://nwb-schema.readthedocs.io/en/stable/format_description.html#doubly-ragged-arrays for a graphical representation of this example. When there is only one electrode for each unit (i.e., each spike time is associated with a single waveform), then the 'waveforms_index' column will have values 1, 2, ..., N, where N is the number of spike events. The number of electrodes for each spike event should be the same within a given unit. The 'electrodes' column should be used to indicate which electrodes are associated with each unit, and the order of the waveforms within a given unit x spike event should be the same as the order of the electrodes referenced in the 'electrodes' column of this table. The number of samples for each waveform must be the same.
        %
        %  - waveforms_index (VectorIndex) - Index into the 'waveforms' dataset. One value for every spike event. See 'waveforms' for more detail.
        %
        %  - waveforms_index_index (VectorIndex) - Index into the 'waveforms_index' dataset. One value for every unit (row in the table). See 'waveforms' for more detail.
        %
        %  - waveforms_sampling_rate (single) - Sampling rate, in hertz.
        %
        % Output Arguments:
        %  - units (types.core.Units) - A Units object
        
        varargin = [{'waveform_mean_unit' 'volts' 'waveform_sd_unit' 'volts' 'waveforms_unit' 'volts'} varargin];
        obj = obj@types.hdmf_common.DynamicTable(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'electrode_group',[]);
        addParameter(p, 'electrodes',[]);
        addParameter(p, 'electrodes_index',[]);
        addParameter(p, 'obs_intervals',[]);
        addParameter(p, 'obs_intervals_index',[]);
        addParameter(p, 'spike_times',[]);
        addParameter(p, 'spike_times_index',[]);
        addParameter(p, 'spike_times_resolution',[]);
        addParameter(p, 'waveform_mean',[]);
        addParameter(p, 'waveform_mean_sampling_rate',[]);
        addParameter(p, 'waveform_mean_unit',[]);
        addParameter(p, 'waveform_sd',[]);
        addParameter(p, 'waveform_sd_sampling_rate',[]);
        addParameter(p, 'waveform_sd_unit',[]);
        addParameter(p, 'waveforms',[]);
        addParameter(p, 'waveforms_index',[]);
        addParameter(p, 'waveforms_index_index',[]);
        addParameter(p, 'waveforms_sampling_rate',[]);
        addParameter(p, 'waveforms_unit',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.electrode_group = p.Results.electrode_group;
        obj.electrodes = p.Results.electrodes;
        obj.electrodes_index = p.Results.electrodes_index;
        obj.obs_intervals = p.Results.obs_intervals;
        obj.obs_intervals_index = p.Results.obs_intervals_index;
        obj.spike_times = p.Results.spike_times;
        obj.spike_times_index = p.Results.spike_times_index;
        obj.spike_times_resolution = p.Results.spike_times_resolution;
        obj.waveform_mean = p.Results.waveform_mean;
        obj.waveform_mean_sampling_rate = p.Results.waveform_mean_sampling_rate;
        obj.waveform_mean_unit = p.Results.waveform_mean_unit;
        obj.waveform_sd = p.Results.waveform_sd;
        obj.waveform_sd_sampling_rate = p.Results.waveform_sd_sampling_rate;
        obj.waveform_sd_unit = p.Results.waveform_sd_unit;
        obj.waveforms = p.Results.waveforms;
        obj.waveforms_index = p.Results.waveforms_index;
        obj.waveforms_index_index = p.Results.waveforms_index_index;
        obj.waveforms_sampling_rate = p.Results.waveforms_sampling_rate;
        obj.waveforms_unit = p.Results.waveforms_unit;

        % Only execute validation/setup code when called directly in this class's
        % constructor, not when invoked through superclass constructor chain
        if strcmp(class(obj), 'types.core.Units') %#ok<STISA>
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
            types.util.dynamictable.checkConfig(obj);
        end
    end
    %% SETTERS
    function set.electrode_group(obj, val)
        obj.electrode_group = obj.validate_electrode_group(val);
    end
    function set.electrodes(obj, val)
        obj.electrodes = obj.validate_electrodes(val);
    end
    function set.electrodes_index(obj, val)
        obj.electrodes_index = obj.validate_electrodes_index(val);
    end
    function set.obs_intervals(obj, val)
        obj.obs_intervals = obj.validate_obs_intervals(val);
    end
    function set.obs_intervals_index(obj, val)
        obj.obs_intervals_index = obj.validate_obs_intervals_index(val);
    end
    function set.spike_times(obj, val)
        obj.spike_times = obj.validate_spike_times(val);
    end
    function set.spike_times_index(obj, val)
        obj.spike_times_index = obj.validate_spike_times_index(val);
    end
    function set.spike_times_resolution(obj, val)
        obj.spike_times_resolution = obj.validate_spike_times_resolution(val);
        obj.postset_spike_times_resolution()
    end
    function postset_spike_times_resolution(obj)
        if isempty(obj.spike_times) && ~isempty(obj.spike_times_resolution)
            obj.warnIfAttributeDependencyMissing('spike_times_resolution', 'spike_times')
        end
        if ~isempty(obj.spike_times) && isobject(obj.spike_times) && isprop(obj.spike_times, 'resolution')
            if ~isempty(obj.spike_times_resolution)
                obj.spike_times.resolution = obj.spike_times_resolution;
            elseif ~isempty(obj.spike_times.resolution)
                obj.spike_times_resolution = obj.spike_times.resolution;
            end
        end
    end
    function set.waveform_mean(obj, val)
        obj.waveform_mean = obj.validate_waveform_mean(val);
    end
    function set.waveform_mean_sampling_rate(obj, val)
        obj.waveform_mean_sampling_rate = obj.validate_waveform_mean_sampling_rate(val);
        obj.postset_waveform_mean_sampling_rate()
    end
    function postset_waveform_mean_sampling_rate(obj)
        if isempty(obj.waveform_mean) && ~isempty(obj.waveform_mean_sampling_rate)
            obj.warnIfAttributeDependencyMissing('waveform_mean_sampling_rate', 'waveform_mean')
        end
        if ~isempty(obj.waveform_mean) && isobject(obj.waveform_mean) && isprop(obj.waveform_mean, 'sampling_rate')
            if ~isempty(obj.waveform_mean_sampling_rate)
                obj.waveform_mean.sampling_rate = obj.waveform_mean_sampling_rate;
            elseif ~isempty(obj.waveform_mean.sampling_rate)
                obj.waveform_mean_sampling_rate = obj.waveform_mean.sampling_rate;
            end
        end
    end
    function set.waveform_sd(obj, val)
        obj.waveform_sd = obj.validate_waveform_sd(val);
    end
    function set.waveform_sd_sampling_rate(obj, val)
        obj.waveform_sd_sampling_rate = obj.validate_waveform_sd_sampling_rate(val);
        obj.postset_waveform_sd_sampling_rate()
    end
    function postset_waveform_sd_sampling_rate(obj)
        if isempty(obj.waveform_sd) && ~isempty(obj.waveform_sd_sampling_rate)
            obj.warnIfAttributeDependencyMissing('waveform_sd_sampling_rate', 'waveform_sd')
        end
        if ~isempty(obj.waveform_sd) && isobject(obj.waveform_sd) && isprop(obj.waveform_sd, 'sampling_rate')
            if ~isempty(obj.waveform_sd_sampling_rate)
                obj.waveform_sd.sampling_rate = obj.waveform_sd_sampling_rate;
            elseif ~isempty(obj.waveform_sd.sampling_rate)
                obj.waveform_sd_sampling_rate = obj.waveform_sd.sampling_rate;
            end
        end
    end
    function set.waveforms(obj, val)
        obj.waveforms = obj.validate_waveforms(val);
    end
    function set.waveforms_index(obj, val)
        obj.waveforms_index = obj.validate_waveforms_index(val);
    end
    function set.waveforms_index_index(obj, val)
        obj.waveforms_index_index = obj.validate_waveforms_index_index(val);
    end
    function set.waveforms_sampling_rate(obj, val)
        obj.waveforms_sampling_rate = obj.validate_waveforms_sampling_rate(val);
        obj.postset_waveforms_sampling_rate()
    end
    function postset_waveforms_sampling_rate(obj)
        if isempty(obj.waveforms) && ~isempty(obj.waveforms_sampling_rate)
            obj.warnIfAttributeDependencyMissing('waveforms_sampling_rate', 'waveforms')
        end
        if ~isempty(obj.waveforms) && isobject(obj.waveforms) && isprop(obj.waveforms, 'sampling_rate')
            if ~isempty(obj.waveforms_sampling_rate)
                obj.waveforms.sampling_rate = obj.waveforms_sampling_rate;
            elseif ~isempty(obj.waveforms.sampling_rate)
                obj.waveforms_sampling_rate = obj.waveforms.sampling_rate;
            end
        end
    end
    %% VALIDATORS
    
    function val = validate_electrode_group(obj, val)
        types.util.checkType('electrode_group', 'types.hdmf_common.VectorData', val);
        if ~isempty(val)
            [val, originalVal] = types.util.unwrapValue(val);
            % Reference to type `ElectrodeGroup`
            val = types.util.validateReferenceType('electrode_group', val, 'types.core.ElectrodeGroup', 'types.untyped.ObjectView');
            val = types.util.rewrapValue(val, originalVal);
        end
    end
    function val = validate_electrodes(obj, val)
        types.util.checkType('electrodes', 'types.hdmf_common.DynamicTableRegion', val);
    end
    function val = validate_electrodes_index(obj, val)
        types.util.checkType('electrodes_index', 'types.hdmf_common.VectorIndex', val);
    end
    function val = validate_obs_intervals(obj, val)
        types.util.checkType('obs_intervals', 'types.hdmf_common.VectorData', val);
        if ~isempty(val)
            [val, originalVal] = types.util.unwrapValue(val);
            val = types.util.checkDtype('obs_intervals', 'double', val);
            types.util.validateShape('obs_intervals', {[2,Inf]}, val)
            val = types.util.rewrapValue(val, originalVal);
        end
    end
    function val = validate_obs_intervals_index(obj, val)
        types.util.checkType('obs_intervals_index', 'types.hdmf_common.VectorIndex', val);
    end
    function val = validate_spike_times(obj, val)
        types.util.checkType('spike_times', 'types.hdmf_common.VectorData', val);
        if ~isempty(val)
            [val, originalVal] = types.util.unwrapValue(val);
            val = types.util.checkDtype('spike_times', 'double', val);
            val = types.util.rewrapValue(val, originalVal);
        end
    end
    function val = validate_spike_times_index(obj, val)
        types.util.checkType('spike_times_index', 'types.hdmf_common.VectorIndex', val);
    end
    function val = validate_spike_times_resolution(obj, val)
        val = types.util.checkDtype('spike_times_resolution', 'double', val);
        types.util.validateShape('spike_times_resolution', {[1]}, val)
    end
    function val = validate_waveform_mean(obj, val)
        types.util.checkType('waveform_mean', 'types.hdmf_common.VectorData', val);
        if ~isempty(val)
            [val, originalVal] = types.util.unwrapValue(val);
            val = types.util.checkDtype('waveform_mean', 'single', val);
            types.util.validateShape('waveform_mean', {[Inf,Inf,Inf], [Inf,Inf]}, val)
            val = types.util.rewrapValue(val, originalVal);
        end
    end
    function val = validate_waveform_mean_sampling_rate(obj, val)
        val = types.util.checkDtype('waveform_mean_sampling_rate', 'single', val);
        types.util.validateShape('waveform_mean_sampling_rate', {[1]}, val)
    end
    function val = validate_waveform_sd(obj, val)
        types.util.checkType('waveform_sd', 'types.hdmf_common.VectorData', val);
        if ~isempty(val)
            [val, originalVal] = types.util.unwrapValue(val);
            val = types.util.checkDtype('waveform_sd', 'single', val);
            types.util.validateShape('waveform_sd', {[Inf,Inf,Inf], [Inf,Inf]}, val)
            val = types.util.rewrapValue(val, originalVal);
        end
    end
    function val = validate_waveform_sd_sampling_rate(obj, val)
        val = types.util.checkDtype('waveform_sd_sampling_rate', 'single', val);
        types.util.validateShape('waveform_sd_sampling_rate', {[1]}, val)
    end
    function val = validate_waveforms(obj, val)
        types.util.checkType('waveforms', 'types.hdmf_common.VectorData', val);
        if ~isempty(val)
            [val, originalVal] = types.util.unwrapValue(val);
            val = types.util.checkDtype('waveforms', 'numeric', val);
            types.util.validateShape('waveforms', {[Inf,Inf]}, val)
            val = types.util.rewrapValue(val, originalVal);
        end
    end
    function val = validate_waveforms_index(obj, val)
        types.util.checkType('waveforms_index', 'types.hdmf_common.VectorIndex', val);
    end
    function val = validate_waveforms_index_index(obj, val)
        types.util.checkType('waveforms_index_index', 'types.hdmf_common.VectorIndex', val);
    end
    function val = validate_waveforms_sampling_rate(obj, val)
        val = types.util.checkDtype('waveforms_sampling_rate', 'single', val);
        types.util.validateShape('waveforms_sampling_rate', {[1]}, val)
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.DynamicTable(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.electrode_group)
            refs = obj.electrode_group.export(fid, [fullpath '/electrode_group'], refs);
        end
        if ~isempty(obj.electrodes)
            refs = obj.electrodes.export(fid, [fullpath '/electrodes'], refs);
        end
        if ~isempty(obj.electrodes_index)
            refs = obj.electrodes_index.export(fid, [fullpath '/electrodes_index'], refs);
        end
        if ~isempty(obj.obs_intervals)
            refs = obj.obs_intervals.export(fid, [fullpath '/obs_intervals'], refs);
        end
        if ~isempty(obj.obs_intervals_index)
            refs = obj.obs_intervals_index.export(fid, [fullpath '/obs_intervals_index'], refs);
        end
        if ~isempty(obj.spike_times)
            refs = obj.spike_times.export(fid, [fullpath '/spike_times'], refs);
        end
        if ~isempty(obj.spike_times_index)
            refs = obj.spike_times_index.export(fid, [fullpath '/spike_times_index'], refs);
        end
        if isempty(obj.spike_times_resolution) && ~isempty(obj.spike_times) && isobject(obj.spike_times) && isprop(obj.spike_times, 'resolution') && ~isempty(obj.spike_times.resolution)
            obj.spike_times_resolution = obj.spike_times.resolution;
        end
        if ~isempty(obj.spike_times) && ~isa(obj.spike_times, 'types.untyped.SoftLink') && ~isa(obj.spike_times, 'types.untyped.ExternalLink') && ~isempty(obj.spike_times_resolution)
            io.writeAttribute(fid, [fullpath '/spike_times/resolution'], obj.spike_times_resolution);
        end
        if ~isempty(obj.waveform_mean)
            refs = obj.waveform_mean.export(fid, [fullpath '/waveform_mean'], refs);
        end
        if isempty(obj.waveform_mean_sampling_rate) && ~isempty(obj.waveform_mean) && isobject(obj.waveform_mean) && isprop(obj.waveform_mean, 'sampling_rate') && ~isempty(obj.waveform_mean.sampling_rate)
            obj.waveform_mean_sampling_rate = obj.waveform_mean.sampling_rate;
        end
        if ~isempty(obj.waveform_mean) && ~isa(obj.waveform_mean, 'types.untyped.SoftLink') && ~isa(obj.waveform_mean, 'types.untyped.ExternalLink') && ~isempty(obj.waveform_mean_sampling_rate)
            io.writeAttribute(fid, [fullpath '/waveform_mean/sampling_rate'], obj.waveform_mean_sampling_rate);
        end
        if isempty(obj.waveform_mean_unit) && ~isempty(obj.waveform_mean) && isobject(obj.waveform_mean) && isprop(obj.waveform_mean, 'unit') && ~isempty(obj.waveform_mean.unit)
            obj.waveform_mean_unit = obj.waveform_mean.unit;
        end
        if ~isempty(obj.waveform_mean) && ~isa(obj.waveform_mean, 'types.untyped.SoftLink') && ~isa(obj.waveform_mean, 'types.untyped.ExternalLink') && ~isempty(obj.waveform_mean_unit)
            io.writeAttribute(fid, [fullpath '/waveform_mean/unit'], obj.waveform_mean_unit);
        end
        if ~isempty(obj.waveform_sd)
            refs = obj.waveform_sd.export(fid, [fullpath '/waveform_sd'], refs);
        end
        if isempty(obj.waveform_sd_sampling_rate) && ~isempty(obj.waveform_sd) && isobject(obj.waveform_sd) && isprop(obj.waveform_sd, 'sampling_rate') && ~isempty(obj.waveform_sd.sampling_rate)
            obj.waveform_sd_sampling_rate = obj.waveform_sd.sampling_rate;
        end
        if ~isempty(obj.waveform_sd) && ~isa(obj.waveform_sd, 'types.untyped.SoftLink') && ~isa(obj.waveform_sd, 'types.untyped.ExternalLink') && ~isempty(obj.waveform_sd_sampling_rate)
            io.writeAttribute(fid, [fullpath '/waveform_sd/sampling_rate'], obj.waveform_sd_sampling_rate);
        end
        if isempty(obj.waveform_sd_unit) && ~isempty(obj.waveform_sd) && isobject(obj.waveform_sd) && isprop(obj.waveform_sd, 'unit') && ~isempty(obj.waveform_sd.unit)
            obj.waveform_sd_unit = obj.waveform_sd.unit;
        end
        if ~isempty(obj.waveform_sd) && ~isa(obj.waveform_sd, 'types.untyped.SoftLink') && ~isa(obj.waveform_sd, 'types.untyped.ExternalLink') && ~isempty(obj.waveform_sd_unit)
            io.writeAttribute(fid, [fullpath '/waveform_sd/unit'], obj.waveform_sd_unit);
        end
        if ~isempty(obj.waveforms)
            refs = obj.waveforms.export(fid, [fullpath '/waveforms'], refs);
        end
        if ~isempty(obj.waveforms_index)
            refs = obj.waveforms_index.export(fid, [fullpath '/waveforms_index'], refs);
        end
        if ~isempty(obj.waveforms_index_index)
            refs = obj.waveforms_index_index.export(fid, [fullpath '/waveforms_index_index'], refs);
        end
        if isempty(obj.waveforms_sampling_rate) && ~isempty(obj.waveforms) && isobject(obj.waveforms) && isprop(obj.waveforms, 'sampling_rate') && ~isempty(obj.waveforms.sampling_rate)
            obj.waveforms_sampling_rate = obj.waveforms.sampling_rate;
        end
        if ~isempty(obj.waveforms) && ~isa(obj.waveforms, 'types.untyped.SoftLink') && ~isa(obj.waveforms, 'types.untyped.ExternalLink') && ~isempty(obj.waveforms_sampling_rate)
            io.writeAttribute(fid, [fullpath '/waveforms/sampling_rate'], obj.waveforms_sampling_rate);
        end
        if isempty(obj.waveforms_unit) && ~isempty(obj.waveforms) && isobject(obj.waveforms) && isprop(obj.waveforms, 'unit') && ~isempty(obj.waveforms.unit)
            obj.waveforms_unit = obj.waveforms.unit;
        end
        if ~isempty(obj.waveforms) && ~isa(obj.waveforms, 'types.untyped.SoftLink') && ~isa(obj.waveforms, 'types.untyped.ExternalLink') && ~isempty(obj.waveforms_unit)
            io.writeAttribute(fid, [fullpath '/waveforms/unit'], obj.waveforms_unit);
        end
    end
end

end