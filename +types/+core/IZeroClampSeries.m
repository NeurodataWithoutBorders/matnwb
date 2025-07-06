classdef IZeroClampSeries < types.core.CurrentClampSeries & types.untyped.GroupClass
% IZEROCLAMPSERIES - Voltage data from an intracellular recording when all current and amplifier settings are off (i.e., CurrentClampSeries fields will be zero). There is no CurrentClampStimulusSeries associated with an IZero series because the amplifier is disconnected and no stimulus can reach the cell.
%
% Required Properties:
%  data, electrode



methods
    function obj = IZeroClampSeries(varargin)
        % IZEROCLAMPSERIES - Constructor for IZeroClampSeries
        %
        % Syntax:
        %  iZeroClampSeries = types.core.IZEROCLAMPSERIES() creates a IZeroClampSeries object with unset property values.
        %
        %  iZeroClampSeries = types.core.IZEROCLAMPSERIES(Name, Value) creates a IZeroClampSeries object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
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
        %  - sweep_number (uint32) - Sweep number, allows to group different PatchClampSeries together.
        %
        %  - timestamps (double) - Timestamps for samples stored in data, in seconds, relative to the common experiment master-clock stored in NWBFile.timestamps_reference_time.
        %
        % Output Arguments:
        %  - iZeroClampSeries (types.core.IZeroClampSeries) - A IZeroClampSeries object
        
        varargin = [{'bias_current' types.util.correctType(0, 'single') 'bridge_balance' types.util.correctType(0, 'single') 'capacitance_compensation' types.util.correctType(0, 'single') 'stimulus_description' 'N/A'} varargin];
        obj = obj@types.core.CurrentClampSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        if strcmp(class(obj), 'types.core.IZeroClampSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    function val = validate_bias_current(obj, val)
        if isequal(val, 0)
            val = 0;
        else
            error('NWB:Type:ReadOnlyProperty', 'Unable to set the ''bias_current'' property of class ''<a href="matlab:doc types.core.IZeroClampSeries">IZeroClampSeries</a>'' because it is read-only.')
        end
    end
    function val = validate_bridge_balance(obj, val)
        if isequal(val, 0)
            val = 0;
        else
            error('NWB:Type:ReadOnlyProperty', 'Unable to set the ''bridge_balance'' property of class ''<a href="matlab:doc types.core.IZeroClampSeries">IZeroClampSeries</a>'' because it is read-only.')
        end
    end
    function val = validate_capacitance_compensation(obj, val)
        if isequal(val, 0)
            val = 0;
        else
            error('NWB:Type:ReadOnlyProperty', 'Unable to set the ''capacitance_compensation'' property of class ''<a href="matlab:doc types.core.IZeroClampSeries">IZeroClampSeries</a>'' because it is read-only.')
        end
    end
    function val = validate_stimulus_description(obj, val)
        if isequal(val, 'N/A')
            val = 'N/A';
        else
            error('NWB:Type:ReadOnlyProperty', 'Unable to set the ''stimulus_description'' property of class ''<a href="matlab:doc types.core.IZeroClampSeries">IZeroClampSeries</a>'' because it is read-only.')
        end
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.CurrentClampSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
    end
end

end