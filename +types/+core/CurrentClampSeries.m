classdef CurrentClampSeries < types.core.PatchClampSeries & types.untyped.GroupClass
% CURRENTCLAMPSERIES - Voltage data from an intracellular current-clamp recording. A corresponding CurrentClampStimulusSeries (stored separately as a stimulus) is used to store the current injected.
%
% Required Properties:
%  data, electrode, stimulus_description


% OPTIONAL PROPERTIES
properties
    bias_current; %  (single) Bias current, in amps.
    bridge_balance; %  (single) Bridge balance, in ohms.
    capacitance_compensation; %  (single) Capacitance compensation, in farads.
end

methods
    function obj = CurrentClampSeries(varargin)
        % CURRENTCLAMPSERIES - Constructor for CurrentClampSeries
        %
        % Syntax:
        %  currentClampSeries = types.core.CURRENTCLAMPSERIES() creates a CurrentClampSeries object with unset property values.
        %
        %  currentClampSeries = types.core.CURRENTCLAMPSERIES(Name, Value) creates a CurrentClampSeries object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - bias_current (single) - Bias current, in amps.
        %
        %  - bridge_balance (single) - Bridge balance, in ohms.
        %
        %  - capacitance_compensation (single) - Capacitance compensation, in farads.
        %
        %  - comments (char) - Human-readable comments about the TimeSeries. This second descriptive field can be used to store additional information, or descriptive information if the primary description field is populated with a computer-readable string.
        %
        %  - control (uint8) - Numerical labels that apply to each time point in data for the purpose of querying and slicing data by these values. If present, the length of this array should be the same size as the first dimension of data.
        %
        %  - control_description (char) - Description of each control value. Must be present if control is present. If present, control_description[0] should describe time points where control == 0.
        %
        %  - data (numeric) - Recorded voltage.
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
        % Output Arguments:
        %  - currentClampSeries (types.core.CurrentClampSeries) - A CurrentClampSeries object
        
        varargin = [{'data_unit' 'volts'} varargin];
        obj = obj@types.core.PatchClampSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'bias_current',[]);
        addParameter(p, 'bridge_balance',[]);
        addParameter(p, 'capacitance_compensation',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.bias_current = p.Results.bias_current;
        obj.bridge_balance = p.Results.bridge_balance;
        obj.capacitance_compensation = p.Results.capacitance_compensation;
        if strcmp(class(obj), 'types.core.CurrentClampSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.bias_current(obj, val)
        obj.bias_current = obj.validate_bias_current(val);
    end
    function set.bridge_balance(obj, val)
        obj.bridge_balance = obj.validate_bridge_balance(val);
    end
    function set.capacitance_compensation(obj, val)
        obj.capacitance_compensation = obj.validate_capacitance_compensation(val);
    end
    %% VALIDATORS
    
    function val = validate_bias_current(obj, val)
        val = types.util.checkDtype('bias_current', 'single', val);
        types.util.validateShape('bias_current', {[1]}, val)
    end
    function val = validate_bridge_balance(obj, val)
        val = types.util.checkDtype('bridge_balance', 'single', val);
        types.util.validateShape('bridge_balance', {[1]}, val)
    end
    function val = validate_capacitance_compensation(obj, val)
        val = types.util.checkDtype('capacitance_compensation', 'single', val);
        types.util.validateShape('capacitance_compensation', {[1]}, val)
    end
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'numeric', val);
        types.util.validateShape('data', {[Inf]}, val)
    end
    function val = validate_data_unit(obj, val)
        if isequal(val, 'volts')
            val = 'volts';
        else
            error('NWB:Type:ReadOnlyProperty', 'Unable to set the ''data_unit'' property of class ''<a href="matlab:doc types.core.CurrentClampSeries">CurrentClampSeries</a>'' because it is read-only.')
        end
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.PatchClampSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.bias_current)
            if startsWith(class(obj.bias_current), 'types.untyped.')
                refs = obj.bias_current.export(fid, [fullpath '/bias_current'], refs);
            elseif ~isempty(obj.bias_current)
                io.writeDataset(fid, [fullpath '/bias_current'], obj.bias_current);
            end
        end
        if ~isempty(obj.bridge_balance)
            if startsWith(class(obj.bridge_balance), 'types.untyped.')
                refs = obj.bridge_balance.export(fid, [fullpath '/bridge_balance'], refs);
            elseif ~isempty(obj.bridge_balance)
                io.writeDataset(fid, [fullpath '/bridge_balance'], obj.bridge_balance);
            end
        end
        if ~isempty(obj.capacitance_compensation)
            if startsWith(class(obj.capacitance_compensation), 'types.untyped.')
                refs = obj.capacitance_compensation.export(fid, [fullpath '/capacitance_compensation'], refs);
            elseif ~isempty(obj.capacitance_compensation)
                io.writeDataset(fid, [fullpath '/capacitance_compensation'], obj.capacitance_compensation);
            end
        end
    end
end

end