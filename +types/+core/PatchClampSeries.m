classdef PatchClampSeries < types.core.TimeSeries & types.untyped.GroupClass
% PATCHCLAMPSERIES - An abstract base class for patch-clamp data - stimulus or response, current or voltage.
%
% Required Properties:
%  data, data_unit, electrode, stimulus_description


% REQUIRED PROPERTIES
properties
    electrode; % REQUIRED IntracellularElectrode
    stimulus_description; % REQUIRED (char) Protocol/stimulus name for this patch-clamp dataset.
end
% OPTIONAL PROPERTIES
properties
    gain; %  (single) Gain of the recording, in units Volt/Amp (v-clamp) or Volt/Volt (c-clamp).
    sweep_number; %  (uint32) Sweep number, allows to group different PatchClampSeries together.
end

methods
    function obj = PatchClampSeries(varargin)
        % PATCHCLAMPSERIES - Constructor for PatchClampSeries
        %
        % Syntax:
        %  patchClampSeries = types.core.PATCHCLAMPSERIES() creates a PatchClampSeries object with unset property values.
        %
        %  patchClampSeries = types.core.PATCHCLAMPSERIES(Name, Value) creates a PatchClampSeries object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - comments (char) - Human-readable comments about the TimeSeries. This second descriptive field can be used to store additional information, or descriptive information if the primary description field is populated with a computer-readable string.
        %
        %  - control (uint8) - Numerical labels that apply to each time point in data for the purpose of querying and slicing data by these values. If present, the length of this array should be the same size as the first dimension of data.
        %
        %  - control_description (char) - Description of each control value. Must be present if control is present. If present, control_description[0] should describe time points where control == 0.
        %
        %  - data (numeric) - Recorded voltage or current.
        %
        %  - data_continuity (char) - Optionally describe the continuity of the data. Can be "continuous", "instantaneous", or "step". For example, a voltage trace would be "continuous", because samples are recorded from a continuous process. An array of lick times would be "instantaneous", because the data represents distinct moments in time. Times of image presentations would be "step" because the picture remains the same until the next timepoint. This field is optional, but is useful in providing information about the underlying data. It may inform the way this data is interpreted, the way it is visualized, and what analysis methods are applicable.
        %
        %  - data_conversion (single) - Scalar to multiply each element in data to convert it to the specified 'unit'. If the data are stored in acquisition system units or other units that require a conversion to be interpretable, multiply the data by 'conversion' to convert the data to the specified 'unit'. e.g. if the data acquisition system stores values in this object as signed 16-bit integers (int16 range -32,768 to 32,767) that correspond to a 5V range (-2.5V to 2.5V), and the data acquisition system gain is 8000X, then the 'conversion' multiplier to get from raw data acquisition values to recorded volts is 2.5/32768/8000 = 9.5367e-9.
        %
        %  - data_offset (single) - Scalar to add to the data after scaling by 'conversion' to finalize its coercion to the specified 'unit'. Two common examples of this include (a) data stored in an unsigned type that requires a shift after scaling to re-center the data, and (b) specialized recording devices that naturally cause a scalar offset with respect to the true units.
        %
        %  - data_resolution (single) - Smallest meaningful difference between values in data, stored in the specified by unit, e.g., the change in value of the least significant bit, or a larger number if signal noise is known to be present. If unknown, use -1.0.
        %
        %  - data_unit (char) - Base unit of measurement for working with the data. Actual stored values are not necessarily stored in these units. To access the data in these units, multiply 'data' by 'conversion' and add 'offset'.
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
        %  - patchClampSeries (types.core.PatchClampSeries) - A PatchClampSeries object
        
        obj = obj@types.core.TimeSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'electrode',[]);
        addParameter(p, 'gain',[]);
        addParameter(p, 'stimulus_description',[]);
        addParameter(p, 'sweep_number',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.electrode = p.Results.electrode;
        obj.gain = p.Results.gain;
        obj.stimulus_description = p.Results.stimulus_description;
        obj.sweep_number = p.Results.sweep_number;
        if strcmp(class(obj), 'types.core.PatchClampSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.electrode(obj, val)
        obj.electrode = obj.validate_electrode(val);
    end
    function set.gain(obj, val)
        obj.gain = obj.validate_gain(val);
    end
    function set.stimulus_description(obj, val)
        obj.stimulus_description = obj.validate_stimulus_description(val);
    end
    function set.sweep_number(obj, val)
        obj.sweep_number = obj.validate_sweep_number(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'numeric', val);
        types.util.validateShape('data', {[Inf]}, val)
    end
    function val = validate_data_unit(obj, val)
        val = types.util.checkDtype('data_unit', 'char', val);
        types.util.validateShape('data_unit', {[1]}, val)
    end
    function val = validate_electrode(obj, val)
        if isa(val, 'types.untyped.SoftLink')
            if isprop(val, 'target')
                types.util.checkDtype('electrode', 'types.core.IntracellularElectrode', val.target);
            end
        else
            val = types.util.checkDtype('electrode', 'types.core.IntracellularElectrode', val);
            if ~isempty(val)
                val = types.untyped.SoftLink(val);
            end
        end
    end
    function val = validate_gain(obj, val)
        val = types.util.checkDtype('gain', 'single', val);
        types.util.validateShape('gain', {[1]}, val)
    end
    function val = validate_stimulus_description(obj, val)
        val = types.util.checkDtype('stimulus_description', 'char', val);
        types.util.validateShape('stimulus_description', {[1]}, val)
    end
    function val = validate_sweep_number(obj, val)
        val = types.util.checkDtype('sweep_number', 'uint32', val);
        types.util.validateShape('sweep_number', {[1]}, val)
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.TimeSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.electrode.export(fid, [fullpath '/electrode'], refs);
        if ~isempty(obj.gain)
            if startsWith(class(obj.gain), 'types.untyped.')
                refs = obj.gain.export(fid, [fullpath '/gain'], refs);
            elseif ~isempty(obj.gain)
                io.writeDataset(fid, [fullpath '/gain'], obj.gain);
            end
        end
        io.writeAttribute(fid, [fullpath '/stimulus_description'], obj.stimulus_description);
        if ~isempty(obj.sweep_number)
            io.writeAttribute(fid, [fullpath '/sweep_number'], obj.sweep_number);
        end
    end
end

end