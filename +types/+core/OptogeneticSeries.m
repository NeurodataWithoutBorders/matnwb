classdef OptogeneticSeries < types.core.TimeSeries & types.untyped.GroupClass
% OPTOGENETICSERIES - An optogenetic stimulus.
%
% Required Properties:
%  data, site


% REQUIRED PROPERTIES
properties
    site; % REQUIRED OptogeneticStimulusSite
end

methods
    function obj = OptogeneticSeries(varargin)
        % OPTOGENETICSERIES - Constructor for OptogeneticSeries
        %
        % Syntax:
        %  optogeneticSeries = types.core.OPTOGENETICSERIES() creates a OptogeneticSeries object with unset property values.
        %
        %  optogeneticSeries = types.core.OPTOGENETICSERIES(Name, Value) creates a OptogeneticSeries object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - comments (char) - Human-readable comments about the TimeSeries. This second descriptive field can be used to store additional information, or descriptive information if the primary description field is populated with a computer-readable string.
        %
        %  - control (uint8) - Numerical labels that apply to each time point in data for the purpose of querying and slicing data by these values. If present, the length of this array should be the same size as the first dimension of data.
        %
        %  - control_description (char) - Description of each control value. Must be present if control is present. If present, control_description[0] should describe time points where control == 0.
        %
        %  - data (numeric) - Applied power for optogenetic stimulus, in watts. Shape can be 1D or 2D. 2D data is meant to be used in an extension of OptogeneticSeries that defines what the second dimension represents.
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
        %  - site (OptogeneticStimulusSite) - Link to OptogeneticStimulusSite object that describes the site to which this stimulus was applied.
        %
        %  - starting_time (double) - Timestamp of the first sample in seconds. When timestamps are uniformly spaced, the timestamp of the first sample can be specified and all subsequent ones calculated from the sampling rate attribute.
        %
        %  - starting_time_rate (single) - Sampling rate, in Hz.
        %
        %  - timestamps (double) - Timestamps for samples stored in data, in seconds, relative to the common experiment master-clock stored in NWBFile.timestamps_reference_time.
        %
        % Output Arguments:
        %  - optogeneticSeries (types.core.OptogeneticSeries) - A OptogeneticSeries object
        
        varargin = [{'data_unit' 'watts'} varargin];
        obj = obj@types.core.TimeSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'site',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.site = p.Results.site;
        if strcmp(class(obj), 'types.core.OptogeneticSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.site(obj, val)
        obj.site = obj.validate_site(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'numeric', val);
        types.util.validateShape('data', {[Inf,Inf], [Inf]}, val)
    end
    function val = validate_data_unit(obj, val)
        if isequal(val, 'watts')
            val = 'watts';
        else
            error('NWB:Type:ReadOnlyProperty', 'Unable to set the ''data_unit'' property of class ''<a href="matlab:doc types.core.OptogeneticSeries">OptogeneticSeries</a>'' because it is read-only.')
        end
    end
    function val = validate_site(obj, val)
        if isa(val, 'types.untyped.SoftLink')
            if isprop(val, 'target')
                types.util.checkDtype('site', 'types.core.OptogeneticStimulusSite', val.target);
            end
        else
            val = types.util.checkDtype('site', 'types.core.OptogeneticStimulusSite', val);
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
        refs = obj.site.export(fid, [fullpath '/site'], refs);
    end
end

end