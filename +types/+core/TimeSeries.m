classdef TimeSeries < types.core.NWBDataInterface & types.untyped.GroupClass
% TIMESERIES - General purpose time series.
%
% Required Properties:
%  data, data_unit


% READONLY PROPERTIES
properties(SetAccess = protected)
    starting_time_unit = "seconds"; %  (char) Unit of measurement for time, which is fixed to 'seconds'.
    timestamps_interval = 1; %  (int32) Value is '1'
    timestamps_unit = "seconds"; %  (char) Unit of measurement for timestamps, which is fixed to 'seconds'.
end
% REQUIRED PROPERTIES
properties
    data; % REQUIRED (any) Data values. Data can be in 1-D, 2-D, 3-D, or 4-D. The first dimension should always represent time. This can also be used to store binary data (e.g., image frames). This can also be a link to data stored in an external file.
    data_unit; % REQUIRED (char) Base unit of measurement for working with the data. Actual stored values are not necessarily stored in these units. To access the data in these units, multiply 'data' by 'conversion' and add 'offset'.
end
% OPTIONAL PROPERTIES
properties
    comments = "no comments"; %  (char) Human-readable comments about the TimeSeries. This second descriptive field can be used to store additional information, or descriptive information if the primary description field is populated with a computer-readable string.
    control; %  (uint8) Numerical labels that apply to each time point in data for the purpose of querying and slicing data by these values. If present, the length of this array should be the same size as the first dimension of data.
    control_description; %  (char) Description of each control value. Must be present if control is present. If present, control_description[0] should describe time points where control == 0.
    data_continuity; %  (char) Optionally describe the continuity of the data. Can be "continuous", "instantaneous", or "step". For example, a voltage trace would be "continuous", because samples are recorded from a continuous process. An array of lick times would be "instantaneous", because the data represents distinct moments in time. Times of image presentations would be "step" because the picture remains the same until the next timepoint. This field is optional, but is useful in providing information about the underlying data. It may inform the way this data is interpreted, the way it is visualized, and what analysis methods are applicable.
    data_conversion = 1; %  (single) Scalar to multiply each element in data to convert it to the specified 'unit'. If the data are stored in acquisition system units or other units that require a conversion to be interpretable, multiply the data by 'conversion' to convert the data to the specified 'unit'. e.g. if the data acquisition system stores values in this object as signed 16-bit integers (int16 range -32,768 to 32,767) that correspond to a 5V range (-2.5V to 2.5V), and the data acquisition system gain is 8000X, then the 'conversion' multiplier to get from raw data acquisition values to recorded volts is 2.5/32768/8000 = 9.5367e-9.
    data_offset = 0; %  (single) Scalar to add to the data after scaling by 'conversion' to finalize its coercion to the specified 'unit'. Two common examples of this include (a) data stored in an unsigned type that requires a shift after scaling to re-center the data, and (b) specialized recording devices that naturally cause a scalar offset with respect to the true units.
    data_resolution = -1; %  (single) Smallest meaningful difference between values in data, stored in the specified by unit, e.g., the change in value of the least significant bit, or a larger number if signal noise is known to be present. If unknown, use -1.0.
    description = "no description"; %  (char) Description of the time series.
    starting_time; %  (double) Timestamp of the first sample in seconds. When timestamps are uniformly spaced, the timestamp of the first sample can be specified and all subsequent ones calculated from the sampling rate attribute.
    starting_time_rate; %  (single) Sampling rate, in Hz.
    timestamps; %  (double) Timestamps for samples stored in data, in seconds, relative to the common experiment master-clock stored in NWBFile.timestamps_reference_time.
end

methods
    function obj = TimeSeries(varargin)
        % TIMESERIES - Constructor for TimeSeries
        %
        % Syntax:
        %  timeSeries = types.core.TIMESERIES() creates a TimeSeries object with unset property values.
        %
        %  timeSeries = types.core.TIMESERIES(Name, Value) creates a TimeSeries object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - comments (char) - Human-readable comments about the TimeSeries. This second descriptive field can be used to store additional information, or descriptive information if the primary description field is populated with a computer-readable string.
        %
        %  - control (uint8) - Numerical labels that apply to each time point in data for the purpose of querying and slicing data by these values. If present, the length of this array should be the same size as the first dimension of data.
        %
        %  - control_description (char) - Description of each control value. Must be present if control is present. If present, control_description[0] should describe time points where control == 0.
        %
        %  - data (any) - Data values. Data can be in 1-D, 2-D, 3-D, or 4-D. The first dimension should always represent time. This can also be used to store binary data (e.g., image frames). This can also be a link to data stored in an external file.
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
        %  - starting_time (double) - Timestamp of the first sample in seconds. When timestamps are uniformly spaced, the timestamp of the first sample can be specified and all subsequent ones calculated from the sampling rate attribute.
        %
        %  - starting_time_rate (single) - Sampling rate, in Hz.
        %
        %  - timestamps (double) - Timestamps for samples stored in data, in seconds, relative to the common experiment master-clock stored in NWBFile.timestamps_reference_time.
        %
        % Output Arguments:
        %  - timeSeries (types.core.TimeSeries) - A TimeSeries object
        
        varargin = [{'comments' 'no comments' 'data_conversion' types.util.correctType(1, 'single') 'data_offset' types.util.correctType(0, 'single') 'data_resolution' types.util.correctType(-1, 'single') 'description' 'no description' 'starting_time_unit' 'seconds' 'timestamps_interval' types.util.correctType(1, 'int32') 'timestamps_unit' 'seconds'} varargin];
        obj = obj@types.core.NWBDataInterface(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'comments',[]);
        addParameter(p, 'control',[]);
        addParameter(p, 'control_description',[]);
        addParameter(p, 'data',[]);
        addParameter(p, 'data_continuity',[]);
        addParameter(p, 'data_conversion',[]);
        addParameter(p, 'data_offset',[]);
        addParameter(p, 'data_resolution',[]);
        addParameter(p, 'data_unit',[]);
        addParameter(p, 'description',[]);
        addParameter(p, 'starting_time',[]);
        addParameter(p, 'starting_time_rate',[]);
        addParameter(p, 'starting_time_unit',[]);
        addParameter(p, 'timestamps',[]);
        addParameter(p, 'timestamps_interval',[]);
        addParameter(p, 'timestamps_unit',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.comments = p.Results.comments;
        obj.control = p.Results.control;
        obj.control_description = p.Results.control_description;
        obj.data = p.Results.data;
        obj.data_continuity = p.Results.data_continuity;
        obj.data_conversion = p.Results.data_conversion;
        obj.data_offset = p.Results.data_offset;
        obj.data_resolution = p.Results.data_resolution;
        obj.data_unit = p.Results.data_unit;
        obj.description = p.Results.description;
        obj.starting_time = p.Results.starting_time;
        obj.starting_time_rate = p.Results.starting_time_rate;
        obj.starting_time_unit = p.Results.starting_time_unit;
        obj.timestamps = p.Results.timestamps;
        obj.timestamps_interval = p.Results.timestamps_interval;
        obj.timestamps_unit = p.Results.timestamps_unit;
        if strcmp(class(obj), 'types.core.TimeSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.comments(obj, val)
        obj.comments = obj.validate_comments(val);
    end
    function set.control(obj, val)
        obj.control = obj.validate_control(val);
    end
    function set.control_description(obj, val)
        obj.control_description = obj.validate_control_description(val);
    end
    function set.data(obj, val)
        obj.data = obj.validate_data(val);
    end
    function set.data_continuity(obj, val)
        obj.data_continuity = obj.validate_data_continuity(val);
        obj.postset_data_continuity()
    end
    function postset_data_continuity(obj)
        if isempty(obj.data) && ~isempty(obj.data_continuity)
            obj.warnIfAttributeDependencyMissing('data_continuity', 'data')
        end
    end
    function set.data_conversion(obj, val)
        obj.data_conversion = obj.validate_data_conversion(val);
        obj.postset_data_conversion()
    end
    function postset_data_conversion(obj)
        if isempty(obj.data) && ~isempty(obj.data_conversion)
            obj.warnIfAttributeDependencyMissing('data_conversion', 'data')
        end
    end
    function set.data_offset(obj, val)
        obj.data_offset = obj.validate_data_offset(val);
        obj.postset_data_offset()
    end
    function postset_data_offset(obj)
        if isempty(obj.data) && ~isempty(obj.data_offset)
            obj.warnIfAttributeDependencyMissing('data_offset', 'data')
        end
    end
    function set.data_resolution(obj, val)
        obj.data_resolution = obj.validate_data_resolution(val);
        obj.postset_data_resolution()
    end
    function postset_data_resolution(obj)
        if isempty(obj.data) && ~isempty(obj.data_resolution)
            obj.warnIfAttributeDependencyMissing('data_resolution', 'data')
        end
    end
    function set.data_unit(obj, val)
        obj.data_unit = obj.validate_data_unit(val);
        obj.postset_data_unit()
    end
    function postset_data_unit(obj)
        if isempty(obj.data) && ~isempty(obj.data_unit)
            obj.warnIfAttributeDependencyMissing('data_unit', 'data')
        end
    end
    function set.description(obj, val)
        obj.description = obj.validate_description(val);
    end
    function set.starting_time(obj, val)
        obj.starting_time = obj.validate_starting_time(val);
    end
    function set.starting_time_rate(obj, val)
        obj.starting_time_rate = obj.validate_starting_time_rate(val);
        obj.postset_starting_time_rate()
    end
    function postset_starting_time_rate(obj)
        if isempty(obj.starting_time) && ~isempty(obj.starting_time_rate)
            obj.warnIfAttributeDependencyMissing('starting_time_rate', 'starting_time')
        end
    end
    function set.timestamps(obj, val)
        obj.timestamps = obj.validate_timestamps(val);
    end
    %% VALIDATORS
    
    function val = validate_comments(obj, val)
        val = types.util.checkDtype('comments', 'char', val);
        types.util.validateShape('comments', {[1]}, val)
    end
    function val = validate_control(obj, val)
        val = types.util.checkDtype('control', 'uint8', val);
        types.util.validateShape('control', {[Inf]}, val)
    end
    function val = validate_control_description(obj, val)
        val = types.util.checkDtype('control_description', 'char', val);
        types.util.validateShape('control_description', {[Inf]}, val)
    end
    function val = validate_data(obj, val)
        types.util.validateShape('data', {[Inf,Inf,Inf,Inf], [Inf,Inf,Inf], [Inf,Inf], [Inf]}, val)
    end
    function val = validate_data_continuity(obj, val)
        val = types.util.checkDtype('data_continuity', 'char', val);
        types.util.validateShape('data_continuity', {[1]}, val)
    end
    function val = validate_data_conversion(obj, val)
        val = types.util.checkDtype('data_conversion', 'single', val);
        types.util.validateShape('data_conversion', {[1]}, val)
    end
    function val = validate_data_offset(obj, val)
        val = types.util.checkDtype('data_offset', 'single', val);
        types.util.validateShape('data_offset', {[1]}, val)
    end
    function val = validate_data_resolution(obj, val)
        val = types.util.checkDtype('data_resolution', 'single', val);
        types.util.validateShape('data_resolution', {[1]}, val)
    end
    function val = validate_data_unit(obj, val)
        val = types.util.checkDtype('data_unit', 'char', val);
        types.util.validateShape('data_unit', {[1]}, val)
    end
    function val = validate_description(obj, val)
        val = types.util.checkDtype('description', 'char', val);
        types.util.validateShape('description', {[1]}, val)
    end
    function val = validate_starting_time(obj, val)
        val = types.util.checkDtype('starting_time', 'double', val);
        types.util.validateShape('starting_time', {[1]}, val)
    end
    function val = validate_starting_time_rate(obj, val)
        val = types.util.checkDtype('starting_time_rate', 'single', val);
        types.util.validateShape('starting_time_rate', {[1]}, val)
    end
    function val = validate_timestamps(obj, val)
        val = types.util.checkDtype('timestamps', 'double', val);
        types.util.validateShape('timestamps', {[Inf]}, val)
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.comments)
            io.writeAttribute(fid, [fullpath '/comments'], obj.comments);
        end
        if ~isempty(obj.control)
            if startsWith(class(obj.control), 'types.untyped.')
                refs = obj.control.export(fid, [fullpath '/control'], refs);
            elseif ~isempty(obj.control)
                io.writeDataset(fid, [fullpath '/control'], obj.control, 'forceArray');
            end
        end
        if ~isempty(obj.control_description)
            if startsWith(class(obj.control_description), 'types.untyped.')
                refs = obj.control_description.export(fid, [fullpath '/control_description'], refs);
            elseif ~isempty(obj.control_description)
                io.writeDataset(fid, [fullpath '/control_description'], obj.control_description, 'forceArray');
            end
        end
        if startsWith(class(obj.data), 'types.untyped.')
            refs = obj.data.export(fid, [fullpath '/data'], refs);
        elseif ~isempty(obj.data)
            io.writeDataset(fid, [fullpath '/data'], obj.data, 'forceArray');
        end
        if ~isempty(obj.data) && ~isa(obj.data, 'types.untyped.SoftLink') && ~isa(obj.data, 'types.untyped.ExternalLink') && ~isempty(obj.data_continuity)
            io.writeAttribute(fid, [fullpath '/data/continuity'], obj.data_continuity);
        end
        if ~isempty(obj.data) && ~isa(obj.data, 'types.untyped.SoftLink') && ~isa(obj.data, 'types.untyped.ExternalLink') && ~isempty(obj.data_conversion)
            io.writeAttribute(fid, [fullpath '/data/conversion'], obj.data_conversion);
        end
        if ~isempty(obj.data) && ~isa(obj.data, 'types.untyped.SoftLink') && ~isa(obj.data, 'types.untyped.ExternalLink') && ~isempty(obj.data_offset)
            io.writeAttribute(fid, [fullpath '/data/offset'], obj.data_offset);
        end
        if ~isempty(obj.data) && ~isa(obj.data, 'types.untyped.SoftLink') && ~isa(obj.data, 'types.untyped.ExternalLink') && ~isempty(obj.data_resolution)
            io.writeAttribute(fid, [fullpath '/data/resolution'], obj.data_resolution);
        end
        if ~isempty(obj.data) && ~isa(obj.data, 'types.untyped.SoftLink') && ~isa(obj.data, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/data/unit'], obj.data_unit);
        elseif isempty(obj.data) && ~isempty(obj.data_unit)
            obj.warnIfPropertyAttributeNotExported('data_unit', 'data', fullpath)
        end
        if ~isempty(obj.description)
            io.writeAttribute(fid, [fullpath '/description'], obj.description);
        end
        if ~isempty(obj.starting_time)
            if startsWith(class(obj.starting_time), 'types.untyped.')
                refs = obj.starting_time.export(fid, [fullpath '/starting_time'], refs);
            elseif ~isempty(obj.starting_time)
                io.writeDataset(fid, [fullpath '/starting_time'], obj.starting_time);
            end
        end
        if ~isempty(obj.starting_time) && ~isa(obj.starting_time, 'types.untyped.SoftLink') && ~isa(obj.starting_time, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/starting_time/rate'], obj.starting_time_rate);
        elseif isempty(obj.starting_time) && ~isempty(obj.starting_time_rate)
            obj.warnIfPropertyAttributeNotExported('starting_time_rate', 'starting_time', fullpath)
        end
        if ~isempty(obj.starting_time) && isempty(obj.starting_time_rate)
            obj.throwErrorIfRequiredDependencyMissing('starting_time_rate', 'starting_time', fullpath)
        end
        if ~isempty(obj.starting_time) && ~isa(obj.starting_time, 'types.untyped.SoftLink') && ~isa(obj.starting_time, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/starting_time/unit'], obj.starting_time_unit);
        end
        if ~isempty(obj.timestamps)
            if startsWith(class(obj.timestamps), 'types.untyped.')
                refs = obj.timestamps.export(fid, [fullpath '/timestamps'], refs);
            elseif ~isempty(obj.timestamps)
                io.writeDataset(fid, [fullpath '/timestamps'], obj.timestamps, 'forceArray');
            end
        end
        if ~isempty(obj.timestamps) && ~isa(obj.timestamps, 'types.untyped.SoftLink') && ~isa(obj.timestamps, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/timestamps/interval'], obj.timestamps_interval);
        end
        if ~isempty(obj.timestamps) && ~isa(obj.timestamps, 'types.untyped.SoftLink') && ~isa(obj.timestamps, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/timestamps/unit'], obj.timestamps_unit);
        end
    end
    %% CUSTOM CONSTRAINTS
    function checkCustomConstraint(obj)
        assert(~isempty(obj.timestamps) || ~isempty(obj.starting_time), ...
            'NWB:TimeSeries:TimeNotSpecified', ...
             "'timestamps' or 'starting_time' must be specified")
        if ~isempty(obj.starting_time)
            assert(~isempty(obj.starting_time_rate), ...
                'NWB:TimeSeries:RateMissing', ...
                "'starting_time_rate' must be specified when 'starting_time' is specified")
        end
    end
end

end