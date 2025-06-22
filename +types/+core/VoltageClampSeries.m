classdef VoltageClampSeries < types.core.PatchClampSeries & types.untyped.GroupClass
% VOLTAGECLAMPSERIES - Current data from an intracellular voltage-clamp recording. A corresponding VoltageClampStimulusSeries (stored separately as a stimulus) is used to store the voltage injected.
%
% Required Properties:
%  data, electrode, stimulus_description


% READONLY PROPERTIES
properties(SetAccess = protected)
    capacitance_fast_unit = "farads"; %  (char) Unit of measurement for capacitance_fast, which is fixed to 'farads'.
    capacitance_slow_unit = "farads"; %  (char) Unit of measurement for capacitance_fast, which is fixed to 'farads'.
    resistance_comp_bandwidth_unit = "hertz"; %  (char) Unit of measurement for resistance_comp_bandwidth, which is fixed to 'hertz'.
    resistance_comp_correction_unit = "percent"; %  (char) Unit of measurement for resistance_comp_correction, which is fixed to 'percent'.
    resistance_comp_prediction_unit = "percent"; %  (char) Unit of measurement for resistance_comp_prediction, which is fixed to 'percent'.
    whole_cell_capacitance_comp_unit = "farads"; %  (char) Unit of measurement for whole_cell_capacitance_comp, which is fixed to 'farads'.
    whole_cell_series_resistance_comp_unit = "ohms"; %  (char) Unit of measurement for whole_cell_series_resistance_comp, which is fixed to 'ohms'.
end
% OPTIONAL PROPERTIES
properties
    capacitance_fast; %  (single) Fast capacitance, in farads.
    capacitance_slow; %  (single) Slow capacitance, in farads.
    resistance_comp_bandwidth; %  (single) Resistance compensation bandwidth, in hertz.
    resistance_comp_correction; %  (single) Resistance compensation correction, in percent.
    resistance_comp_prediction; %  (single) Resistance compensation prediction, in percent.
    whole_cell_capacitance_comp; %  (single) Whole cell capacitance compensation, in farads.
    whole_cell_series_resistance_comp; %  (single) Whole cell series resistance compensation, in ohms.
end

methods
    function obj = VoltageClampSeries(varargin)
        % VOLTAGECLAMPSERIES - Constructor for VoltageClampSeries
        %
        % Syntax:
        %  voltageClampSeries = types.core.VOLTAGECLAMPSERIES() creates a VoltageClampSeries object with unset property values.
        %
        %  voltageClampSeries = types.core.VOLTAGECLAMPSERIES(Name, Value) creates a VoltageClampSeries object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - capacitance_fast (single) - Fast capacitance, in farads.
        %
        %  - capacitance_slow (single) - Slow capacitance, in farads.
        %
        %  - comments (char) - Human-readable comments about the TimeSeries. This second descriptive field can be used to store additional information, or descriptive information if the primary description field is populated with a computer-readable string.
        %
        %  - control (uint8) - Numerical labels that apply to each time point in data for the purpose of querying and slicing data by these values. If present, the length of this array should be the same size as the first dimension of data.
        %
        %  - control_description (char) - Description of each control value. Must be present if control is present. If present, control_description[0] should describe time points where control == 0.
        %
        %  - data (numeric) - Recorded current.
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
        %  - electrode (IntracellularElectrode) - Link to IntracellularElectrode object that describes the electrode that was used to apply or record this data.
        %
        %  - gain (single) - Gain of the recording, in units Volt/Amp (v-clamp) or Volt/Volt (c-clamp).
        %
        %  - resistance_comp_bandwidth (single) - Resistance compensation bandwidth, in hertz.
        %
        %  - resistance_comp_correction (single) - Resistance compensation correction, in percent.
        %
        %  - resistance_comp_prediction (single) - Resistance compensation prediction, in percent.
        %
        %  - starting_time (double) - Timestamp of the first sample in seconds. When timestamps are uniformly spaced, the timestamp of the first sample can be specified and all subsequent ones calculated from the sampling rate attribute.
        %
        %  - starting_time_rate (single) - Sampling rate, in Hz.
        %
        %  - stimulus_description (char) - Protocol/stimulus name for this patch-clamp dataset.
        %
        %  - sweep_number (uint32) - Sweep number, allows to group different PatchClampSeries together.
        %
        %  - timestamps (double) - Timestamps for samples stored in data, in seconds, relative to the common experiment master-clock stored in NWBFile.timestamps_reference_time.
        %
        %  - whole_cell_capacitance_comp (single) - Whole cell capacitance compensation, in farads.
        %
        %  - whole_cell_series_resistance_comp (single) - Whole cell series resistance compensation, in ohms.
        %
        % Output Arguments:
        %  - voltageClampSeries (types.core.VoltageClampSeries) - A VoltageClampSeries object
        
        varargin = [{'capacitance_fast_unit' 'farads' 'capacitance_slow_unit' 'farads' 'data_unit' 'amperes' 'resistance_comp_bandwidth_unit' 'hertz' 'resistance_comp_correction_unit' 'percent' 'resistance_comp_prediction_unit' 'percent' 'whole_cell_capacitance_comp_unit' 'farads' 'whole_cell_series_resistance_comp_unit' 'ohms'} varargin];
        obj = obj@types.core.PatchClampSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'capacitance_fast',[]);
        addParameter(p, 'capacitance_fast_unit',[]);
        addParameter(p, 'capacitance_slow',[]);
        addParameter(p, 'capacitance_slow_unit',[]);
        addParameter(p, 'resistance_comp_bandwidth',[]);
        addParameter(p, 'resistance_comp_bandwidth_unit',[]);
        addParameter(p, 'resistance_comp_correction',[]);
        addParameter(p, 'resistance_comp_correction_unit',[]);
        addParameter(p, 'resistance_comp_prediction',[]);
        addParameter(p, 'resistance_comp_prediction_unit',[]);
        addParameter(p, 'whole_cell_capacitance_comp',[]);
        addParameter(p, 'whole_cell_capacitance_comp_unit',[]);
        addParameter(p, 'whole_cell_series_resistance_comp',[]);
        addParameter(p, 'whole_cell_series_resistance_comp_unit',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.capacitance_fast = p.Results.capacitance_fast;
        obj.capacitance_fast_unit = p.Results.capacitance_fast_unit;
        obj.capacitance_slow = p.Results.capacitance_slow;
        obj.capacitance_slow_unit = p.Results.capacitance_slow_unit;
        obj.resistance_comp_bandwidth = p.Results.resistance_comp_bandwidth;
        obj.resistance_comp_bandwidth_unit = p.Results.resistance_comp_bandwidth_unit;
        obj.resistance_comp_correction = p.Results.resistance_comp_correction;
        obj.resistance_comp_correction_unit = p.Results.resistance_comp_correction_unit;
        obj.resistance_comp_prediction = p.Results.resistance_comp_prediction;
        obj.resistance_comp_prediction_unit = p.Results.resistance_comp_prediction_unit;
        obj.whole_cell_capacitance_comp = p.Results.whole_cell_capacitance_comp;
        obj.whole_cell_capacitance_comp_unit = p.Results.whole_cell_capacitance_comp_unit;
        obj.whole_cell_series_resistance_comp = p.Results.whole_cell_series_resistance_comp;
        obj.whole_cell_series_resistance_comp_unit = p.Results.whole_cell_series_resistance_comp_unit;
        if strcmp(class(obj), 'types.core.VoltageClampSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.capacitance_fast(obj, val)
        obj.capacitance_fast = obj.validate_capacitance_fast(val);
    end
    function set.capacitance_slow(obj, val)
        obj.capacitance_slow = obj.validate_capacitance_slow(val);
    end
    function set.resistance_comp_bandwidth(obj, val)
        obj.resistance_comp_bandwidth = obj.validate_resistance_comp_bandwidth(val);
    end
    function set.resistance_comp_correction(obj, val)
        obj.resistance_comp_correction = obj.validate_resistance_comp_correction(val);
    end
    function set.resistance_comp_prediction(obj, val)
        obj.resistance_comp_prediction = obj.validate_resistance_comp_prediction(val);
    end
    function set.whole_cell_capacitance_comp(obj, val)
        obj.whole_cell_capacitance_comp = obj.validate_whole_cell_capacitance_comp(val);
    end
    function set.whole_cell_series_resistance_comp(obj, val)
        obj.whole_cell_series_resistance_comp = obj.validate_whole_cell_series_resistance_comp(val);
    end
    %% VALIDATORS
    
    function val = validate_capacitance_fast(obj, val)
        val = types.util.checkDtype('capacitance_fast', 'single', val);
        types.util.validateShape('capacitance_fast', {[1]}, val)
    end
    function val = validate_capacitance_slow(obj, val)
        val = types.util.checkDtype('capacitance_slow', 'single', val);
        types.util.validateShape('capacitance_slow', {[1]}, val)
    end
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'numeric', val);
        types.util.validateShape('data', {[Inf]}, val)
    end
    function val = validate_data_unit(obj, val)
        if isequal(val, 'amperes')
            val = 'amperes';
        else
            error('NWB:Type:ReadOnlyProperty', 'Unable to set the ''data_unit'' property of class ''<a href="matlab:doc types.core.VoltageClampSeries">VoltageClampSeries</a>'' because it is read-only.')
        end
    end
    function val = validate_resistance_comp_bandwidth(obj, val)
        val = types.util.checkDtype('resistance_comp_bandwidth', 'single', val);
        types.util.validateShape('resistance_comp_bandwidth', {[1]}, val)
    end
    function val = validate_resistance_comp_correction(obj, val)
        val = types.util.checkDtype('resistance_comp_correction', 'single', val);
        types.util.validateShape('resistance_comp_correction', {[1]}, val)
    end
    function val = validate_resistance_comp_prediction(obj, val)
        val = types.util.checkDtype('resistance_comp_prediction', 'single', val);
        types.util.validateShape('resistance_comp_prediction', {[1]}, val)
    end
    function val = validate_whole_cell_capacitance_comp(obj, val)
        val = types.util.checkDtype('whole_cell_capacitance_comp', 'single', val);
        types.util.validateShape('whole_cell_capacitance_comp', {[1]}, val)
    end
    function val = validate_whole_cell_series_resistance_comp(obj, val)
        val = types.util.checkDtype('whole_cell_series_resistance_comp', 'single', val);
        types.util.validateShape('whole_cell_series_resistance_comp', {[1]}, val)
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.PatchClampSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.capacitance_fast)
            if startsWith(class(obj.capacitance_fast), 'types.untyped.')
                refs = obj.capacitance_fast.export(fid, [fullpath '/capacitance_fast'], refs);
            elseif ~isempty(obj.capacitance_fast)
                io.writeDataset(fid, [fullpath '/capacitance_fast'], obj.capacitance_fast);
            end
        end
        if ~isempty(obj.capacitance_fast) && ~isa(obj.capacitance_fast, 'types.untyped.SoftLink') && ~isa(obj.capacitance_fast, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/capacitance_fast/unit'], obj.capacitance_fast_unit);
        end
        if ~isempty(obj.capacitance_slow)
            if startsWith(class(obj.capacitance_slow), 'types.untyped.')
                refs = obj.capacitance_slow.export(fid, [fullpath '/capacitance_slow'], refs);
            elseif ~isempty(obj.capacitance_slow)
                io.writeDataset(fid, [fullpath '/capacitance_slow'], obj.capacitance_slow);
            end
        end
        if ~isempty(obj.capacitance_slow) && ~isa(obj.capacitance_slow, 'types.untyped.SoftLink') && ~isa(obj.capacitance_slow, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/capacitance_slow/unit'], obj.capacitance_slow_unit);
        end
        if ~isempty(obj.resistance_comp_bandwidth)
            if startsWith(class(obj.resistance_comp_bandwidth), 'types.untyped.')
                refs = obj.resistance_comp_bandwidth.export(fid, [fullpath '/resistance_comp_bandwidth'], refs);
            elseif ~isempty(obj.resistance_comp_bandwidth)
                io.writeDataset(fid, [fullpath '/resistance_comp_bandwidth'], obj.resistance_comp_bandwidth);
            end
        end
        if ~isempty(obj.resistance_comp_bandwidth) && ~isa(obj.resistance_comp_bandwidth, 'types.untyped.SoftLink') && ~isa(obj.resistance_comp_bandwidth, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/resistance_comp_bandwidth/unit'], obj.resistance_comp_bandwidth_unit);
        end
        if ~isempty(obj.resistance_comp_correction)
            if startsWith(class(obj.resistance_comp_correction), 'types.untyped.')
                refs = obj.resistance_comp_correction.export(fid, [fullpath '/resistance_comp_correction'], refs);
            elseif ~isempty(obj.resistance_comp_correction)
                io.writeDataset(fid, [fullpath '/resistance_comp_correction'], obj.resistance_comp_correction);
            end
        end
        if ~isempty(obj.resistance_comp_correction) && ~isa(obj.resistance_comp_correction, 'types.untyped.SoftLink') && ~isa(obj.resistance_comp_correction, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/resistance_comp_correction/unit'], obj.resistance_comp_correction_unit);
        end
        if ~isempty(obj.resistance_comp_prediction)
            if startsWith(class(obj.resistance_comp_prediction), 'types.untyped.')
                refs = obj.resistance_comp_prediction.export(fid, [fullpath '/resistance_comp_prediction'], refs);
            elseif ~isempty(obj.resistance_comp_prediction)
                io.writeDataset(fid, [fullpath '/resistance_comp_prediction'], obj.resistance_comp_prediction);
            end
        end
        if ~isempty(obj.resistance_comp_prediction) && ~isa(obj.resistance_comp_prediction, 'types.untyped.SoftLink') && ~isa(obj.resistance_comp_prediction, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/resistance_comp_prediction/unit'], obj.resistance_comp_prediction_unit);
        end
        if ~isempty(obj.whole_cell_capacitance_comp)
            if startsWith(class(obj.whole_cell_capacitance_comp), 'types.untyped.')
                refs = obj.whole_cell_capacitance_comp.export(fid, [fullpath '/whole_cell_capacitance_comp'], refs);
            elseif ~isempty(obj.whole_cell_capacitance_comp)
                io.writeDataset(fid, [fullpath '/whole_cell_capacitance_comp'], obj.whole_cell_capacitance_comp);
            end
        end
        if ~isempty(obj.whole_cell_capacitance_comp) && ~isa(obj.whole_cell_capacitance_comp, 'types.untyped.SoftLink') && ~isa(obj.whole_cell_capacitance_comp, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/whole_cell_capacitance_comp/unit'], obj.whole_cell_capacitance_comp_unit);
        end
        if ~isempty(obj.whole_cell_series_resistance_comp)
            if startsWith(class(obj.whole_cell_series_resistance_comp), 'types.untyped.')
                refs = obj.whole_cell_series_resistance_comp.export(fid, [fullpath '/whole_cell_series_resistance_comp'], refs);
            elseif ~isempty(obj.whole_cell_series_resistance_comp)
                io.writeDataset(fid, [fullpath '/whole_cell_series_resistance_comp'], obj.whole_cell_series_resistance_comp);
            end
        end
        if ~isempty(obj.whole_cell_series_resistance_comp) && ~isa(obj.whole_cell_series_resistance_comp, 'types.untyped.SoftLink') && ~isa(obj.whole_cell_series_resistance_comp, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/whole_cell_series_resistance_comp/unit'], obj.whole_cell_series_resistance_comp_unit);
        end
    end
end

end