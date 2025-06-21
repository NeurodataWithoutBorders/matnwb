classdef AbstractFeatureSeries < types.core.TimeSeries & types.untyped.GroupClass
% ABSTRACTFEATURESERIES - Abstract features, such as quantitative descriptions of sensory stimuli. The TimeSeries::data field is a 2D array, storing those features (e.g., for visual grating stimulus this might be orientation, spatial frequency and contrast). Null stimuli (eg, uniform gray) can be marked as being an independent feature (eg, 1.0 for gray, 0.0 for actual stimulus) or by storing NaNs for feature values, or through use of the TimeSeries::control fields. A set of features is considered to persist until the next set of features is defined. The final set of features stored should be the null set. This is useful when storing the raw stimulus is impractical.
%
% Required Properties:
%  data, features


% REQUIRED PROPERTIES
properties
    features; % REQUIRED (char) Description of the features represented in TimeSeries::data.
end
% OPTIONAL PROPERTIES
properties
    feature_units; %  (char) Units of each feature.
end

methods
    function obj = AbstractFeatureSeries(varargin)
        % ABSTRACTFEATURESERIES - Constructor for AbstractFeatureSeries
        %
        % Syntax:
        %  abstractFeatureSeries = types.core.ABSTRACTFEATURESERIES() creates a AbstractFeatureSeries object with unset property values.
        %
        %  abstractFeatureSeries = types.core.ABSTRACTFEATURESERIES(Name, Value) creates a AbstractFeatureSeries object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - comments (char) - Human-readable comments about the TimeSeries. This second descriptive field can be used to store additional information, or descriptive information if the primary description field is populated with a computer-readable string.
        %
        %  - control (uint8) - Numerical labels that apply to each time point in data for the purpose of querying and slicing data by these values. If present, the length of this array should be the same size as the first dimension of data.
        %
        %  - control_description (char) - Description of each control value. Must be present if control is present. If present, control_description[0] should describe time points where control == 0.
        %
        %  - data (numeric) - Values of each feature at each time.
        %
        %  - data_continuity (char) - Optionally describe the continuity of the data. Can be "continuous", "instantaneous", or "step". For example, a voltage trace would be "continuous", because samples are recorded from a continuous process. An array of lick times would be "instantaneous", because the data represents distinct moments in time. Times of image presentations would be "step" because the picture remains the same until the next timepoint. This field is optional, but is useful in providing information about the underlying data. It may inform the way this data is interpreted, the way it is visualized, and what analysis methods are applicable.
        %
        %  - data_conversion (single) - Scalar to multiply each element in data to convert it to the specified 'unit'. If the data are stored in acquisition system units or other units that require a conversion to be interpretable, multiply the data by 'conversion' to convert the data to the specified 'unit'. e.g. if the data acquisition system stores values in this object as signed 16-bit integers (int16 range -32,768 to 32,767) that correspond to a 5V range (-2.5V to 2.5V), and the data acquisition system gain is 8000X, then the 'conversion' multiplier to get from raw data acquisition values to recorded volts is 2.5/32768/8000 = 9.5367e-9.
        %
        %  - data_offset (single) - Scalar to add to the data after scaling by 'conversion' to finalize its coercion to the specified 'unit'. Two common examples of this include (a) data stored in an unsigned type that requires a shift after scaling to re-center the data, and (b) specialized recording devices that naturally cause a scalar offset with respect to the true units.
        %
        %  - data_resolution (single) - Smallest meaningful difference between values in data, stored in the specified by unit, e.g., the change in value of the least significant bit, or a larger number if signal noise is known to be present. If unknown, use -1.0.
        %
        %  - data_unit (char) - Since there can be different units for different features, store the units in 'feature_units'. The default value for this attribute is "see 'feature_units'".
        %
        %  - description (char) - Description of the time series.
        %
        %  - feature_units (char) - Units of each feature.
        %
        %  - features (char) - Description of the features represented in TimeSeries::data.
        %
        %  - starting_time (double) - Timestamp of the first sample in seconds. When timestamps are uniformly spaced, the timestamp of the first sample can be specified and all subsequent ones calculated from the sampling rate attribute.
        %
        %  - starting_time_rate (single) - Sampling rate, in Hz.
        %
        %  - timestamps (double) - Timestamps for samples stored in data, in seconds, relative to the common experiment master-clock stored in NWBFile.timestamps_reference_time.
        %
        % Output Arguments:
        %  - abstractFeatureSeries (types.core.AbstractFeatureSeries) - A AbstractFeatureSeries object
        
        varargin = [{'data_unit' 'see `feature_units`'} varargin];
        obj = obj@types.core.TimeSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'feature_units',[]);
        addParameter(p, 'features',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.feature_units = p.Results.feature_units;
        obj.features = p.Results.features;
        if strcmp(class(obj), 'types.core.AbstractFeatureSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.feature_units(obj, val)
        obj.feature_units = obj.validate_feature_units(val);
    end
    function set.features(obj, val)
        obj.features = obj.validate_features(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'numeric', val);
        types.util.validateShape('data', {[Inf,Inf], [Inf]}, val)
    end
    function val = validate_data_unit(obj, val)
        val = types.util.checkDtype('data_unit', 'char', val);
        types.util.validateShape('data_unit', {[1]}, val)
    end
    function val = validate_feature_units(obj, val)
        val = types.util.checkDtype('feature_units', 'char', val);
        types.util.validateShape('feature_units', {[Inf]}, val)
    end
    function val = validate_features(obj, val)
        val = types.util.checkDtype('features', 'char', val);
        types.util.validateShape('features', {[Inf]}, val)
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.TimeSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.feature_units)
            if startsWith(class(obj.feature_units), 'types.untyped.')
                refs = obj.feature_units.export(fid, [fullpath '/feature_units'], refs);
            elseif ~isempty(obj.feature_units)
                io.writeDataset(fid, [fullpath '/feature_units'], obj.feature_units, 'forceArray');
            end
        end
        if startsWith(class(obj.features), 'types.untyped.')
            refs = obj.features.export(fid, [fullpath '/features'], refs);
        elseif ~isempty(obj.features)
            io.writeDataset(fid, [fullpath '/features'], obj.features, 'forceArray');
        end
    end
end

end