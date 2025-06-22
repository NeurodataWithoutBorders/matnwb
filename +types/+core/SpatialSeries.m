classdef SpatialSeries < types.core.TimeSeries & types.untyped.GroupClass
% SPATIALSERIES - Direction, e.g., of gaze or travel, or position. The TimeSeries::data field is a 2D array storing position or direction relative to some reference frame. Array structure: [num measurements] [num dimensions]. Each SpatialSeries has a text dataset reference_frame that indicates the zero-position, or the zero-axes for direction. For example, if representing gaze direction, 'straight-ahead' might be a specific pixel on the monitor, or some other point in space. For position data, the 0,0 point might be the top-left corner of an enclosure, as viewed from the tracking camera. The unit of data will indicate how to interpret SpatialSeries values.
%
% Required Properties:
%  data


% OPTIONAL PROPERTIES
properties
    reference_frame; %  (char) Description defining what exactly 'straight-ahead' means.
end

methods
    function obj = SpatialSeries(varargin)
        % SPATIALSERIES - Constructor for SpatialSeries
        %
        % Syntax:
        %  spatialSeries = types.core.SPATIALSERIES() creates a SpatialSeries object with unset property values.
        %
        %  spatialSeries = types.core.SPATIALSERIES(Name, Value) creates a SpatialSeries object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - comments (char) - Human-readable comments about the TimeSeries. This second descriptive field can be used to store additional information, or descriptive information if the primary description field is populated with a computer-readable string.
        %
        %  - control (uint8) - Numerical labels that apply to each time point in data for the purpose of querying and slicing data by these values. If present, the length of this array should be the same size as the first dimension of data.
        %
        %  - control_description (char) - Description of each control value. Must be present if control is present. If present, control_description[0] should describe time points where control == 0.
        %
        %  - data (numeric) - 1-D or 2-D array storing position or direction relative to some reference frame.
        %
        %  - data_continuity (char) - Optionally describe the continuity of the data. Can be "continuous", "instantaneous", or "step". For example, a voltage trace would be "continuous", because samples are recorded from a continuous process. An array of lick times would be "instantaneous", because the data represents distinct moments in time. Times of image presentations would be "step" because the picture remains the same until the next timepoint. This field is optional, but is useful in providing information about the underlying data. It may inform the way this data is interpreted, the way it is visualized, and what analysis methods are applicable.
        %
        %  - data_conversion (single) - Scalar to multiply each element in data to convert it to the specified 'unit'. If the data are stored in acquisition system units or other units that require a conversion to be interpretable, multiply the data by 'conversion' to convert the data to the specified 'unit'. e.g. if the data acquisition system stores values in this object as signed 16-bit integers (int16 range -32,768 to 32,767) that correspond to a 5V range (-2.5V to 2.5V), and the data acquisition system gain is 8000X, then the 'conversion' multiplier to get from raw data acquisition values to recorded volts is 2.5/32768/8000 = 9.5367e-9.
        %
        %  - data_offset (single) - Scalar to add to the data after scaling by 'conversion' to finalize its coercion to the specified 'unit'. Two common examples of this include (a) data stored in an unsigned type that requires a shift after scaling to re-center the data, and (b) specialized recording devices that naturally cause a scalar offset with respect to the true units.
        %
        %  - data_resolution (single) - Smallest meaningful difference between values in data, stored in the specified by unit, e.g., the change in value of the least significant bit, or a larger number if signal noise is known to be present. If unknown, use -1.0.
        %
        %  - data_unit (char) - Base unit of measurement for working with the data. The default value is 'meters'. Actual stored values are not necessarily stored in these units. To access the data in these units, multiply 'data' by 'conversion' and add 'offset'.
        %
        %  - description (char) - Description of the time series.
        %
        %  - reference_frame (char) - Description defining what exactly 'straight-ahead' means.
        %
        %  - starting_time (double) - Timestamp of the first sample in seconds. When timestamps are uniformly spaced, the timestamp of the first sample can be specified and all subsequent ones calculated from the sampling rate attribute.
        %
        %  - starting_time_rate (single) - Sampling rate, in Hz.
        %
        %  - timestamps (double) - Timestamps for samples stored in data, in seconds, relative to the common experiment master-clock stored in NWBFile.timestamps_reference_time.
        %
        % Output Arguments:
        %  - spatialSeries (types.core.SpatialSeries) - A SpatialSeries object
        
        varargin = [{'data_unit' 'meters'} varargin];
        obj = obj@types.core.TimeSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'reference_frame',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.reference_frame = p.Results.reference_frame;
        if strcmp(class(obj), 'types.core.SpatialSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.reference_frame(obj, val)
        obj.reference_frame = obj.validate_reference_frame(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'numeric', val);
        types.util.validateShape('data', {[3,Inf], [2,Inf], [1,Inf], [Inf]}, val)
    end
    function val = validate_data_unit(obj, val)
        val = types.util.checkDtype('data_unit', 'char', val);
        types.util.validateShape('data_unit', {[1]}, val)
    end
    function val = validate_reference_frame(obj, val)
        val = types.util.checkDtype('reference_frame', 'char', val);
        types.util.validateShape('reference_frame', {[1]}, val)
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.TimeSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.reference_frame)
            if startsWith(class(obj.reference_frame), 'types.untyped.')
                refs = obj.reference_frame.export(fid, [fullpath '/reference_frame'], refs);
            elseif ~isempty(obj.reference_frame)
                io.writeDataset(fid, [fullpath '/reference_frame'], obj.reference_frame);
            end
        end
    end
end

end