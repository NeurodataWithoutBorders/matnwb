classdef ImageSeries < types.core.TimeSeries & types.untyped.GroupClass
% IMAGESERIES - General image data that is common between acquisition and stimulus time series. Sometimes the image data is stored in the file in a raw format while other times it will be stored as a series of external image files in the host file system. The data field will either be binary data, if the data is stored in the NWB file, or empty, if the data is stored in an external image stack. [frame][x][y] or [frame][x][y][z].
%
% Required Properties:
%  data, data_unit


% OPTIONAL PROPERTIES
properties
    device; %  Device
    dimension; %  (int32) Number of pixels on x, y, (and z) axes.
    external_file; %  (char) Paths to one or more external file(s). The field is only present if format='external'. This is only relevant if the image series is stored in the file system as one or more image file(s). This field should NOT be used if the image is stored in another NWB file and that file is linked to this file.
    external_file_starting_frame; %  (int32) Each external image may contain one or more consecutive frames of the full ImageSeries. This attribute serves as an index to indicate which frames each file contains, to facilitate random access. The 'starting_frame' attribute, hence, contains a list of frame numbers within the full ImageSeries of the first frame of each file listed in the parent 'external_file' dataset. Zero-based indexing is used (hence, the first element will always be zero). For example, if the 'external_file' dataset has three paths to files and the first file has 5 frames, the second file has 10 frames, and the third file has 20 frames, then this attribute will have values [0, 5, 15]. If there is a single external file that holds all of the frames of the ImageSeries (and so there is a single element in the 'external_file' dataset), then this attribute should have value [0].
    format = "raw"; %  (char) Format of image. If this is 'external', then the attribute 'external_file' contains the path information to the image files. If this is 'raw', then the raw (single-channel) binary data is stored in the 'data' dataset. If this attribute is not present, then the default format='raw' case is assumed.
end

methods
    function obj = ImageSeries(varargin)
        % IMAGESERIES - Constructor for ImageSeries
        %
        % Syntax:
        %  imageSeries = types.core.IMAGESERIES() creates a ImageSeries object with unset property values.
        %
        %  imageSeries = types.core.IMAGESERIES(Name, Value) creates a ImageSeries object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - comments (char) - Human-readable comments about the TimeSeries. This second descriptive field can be used to store additional information, or descriptive information if the primary description field is populated with a computer-readable string.
        %
        %  - control (uint8) - Numerical labels that apply to each time point in data for the purpose of querying and slicing data by these values. If present, the length of this array should be the same size as the first dimension of data.
        %
        %  - control_description (char) - Description of each control value. Must be present if control is present. If present, control_description[0] should describe time points where control == 0.
        %
        %  - data (numeric) - Binary data representing images across frames. If data are stored in an external file, this should be an empty 3D array.
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
        %  - device (Device) - Link to the Device object that was used to capture these images.
        %
        %  - dimension (int32) - Number of pixels on x, y, (and z) axes.
        %
        %  - external_file (char) - Paths to one or more external file(s). The field is only present if format='external'. This is only relevant if the image series is stored in the file system as one or more image file(s). This field should NOT be used if the image is stored in another NWB file and that file is linked to this file.
        %
        %  - external_file_starting_frame (int32) - Each external image may contain one or more consecutive frames of the full ImageSeries. This attribute serves as an index to indicate which frames each file contains, to facilitate random access. The 'starting_frame' attribute, hence, contains a list of frame numbers within the full ImageSeries of the first frame of each file listed in the parent 'external_file' dataset. Zero-based indexing is used (hence, the first element will always be zero). For example, if the 'external_file' dataset has three paths to files and the first file has 5 frames, the second file has 10 frames, and the third file has 20 frames, then this attribute will have values [0, 5, 15]. If there is a single external file that holds all of the frames of the ImageSeries (and so there is a single element in the 'external_file' dataset), then this attribute should have value [0].
        %
        %  - format (char) - Format of image. If this is 'external', then the attribute 'external_file' contains the path information to the image files. If this is 'raw', then the raw (single-channel) binary data is stored in the 'data' dataset. If this attribute is not present, then the default format='raw' case is assumed.
        %
        %  - starting_time (double) - Timestamp of the first sample in seconds. When timestamps are uniformly spaced, the timestamp of the first sample can be specified and all subsequent ones calculated from the sampling rate attribute.
        %
        %  - starting_time_rate (single) - Sampling rate, in Hz.
        %
        %  - timestamps (double) - Timestamps for samples stored in data, in seconds, relative to the common experiment master-clock stored in NWBFile.timestamps_reference_time.
        %
        % Output Arguments:
        %  - imageSeries (types.core.ImageSeries) - A ImageSeries object
        
        obj = obj@types.core.TimeSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'device',[]);
        addParameter(p, 'dimension',[]);
        addParameter(p, 'external_file',[]);
        addParameter(p, 'external_file_starting_frame',[]);
        addParameter(p, 'format',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.device = p.Results.device;
        obj.dimension = p.Results.dimension;
        obj.external_file = p.Results.external_file;
        obj.external_file_starting_frame = p.Results.external_file_starting_frame;
        obj.format = p.Results.format;
        if strcmp(class(obj), 'types.core.ImageSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.device(obj, val)
        obj.device = obj.validate_device(val);
    end
    function set.dimension(obj, val)
        obj.dimension = obj.validate_dimension(val);
    end
    function set.external_file(obj, val)
        obj.external_file = obj.validate_external_file(val);
    end
    function set.external_file_starting_frame(obj, val)
        obj.external_file_starting_frame = obj.validate_external_file_starting_frame(val);
        obj.postset_external_file_starting_frame()
    end
    function postset_external_file_starting_frame(obj)
        if isempty(obj.external_file) && ~isempty(obj.external_file_starting_frame)
            obj.warnIfAttributeDependencyMissing('external_file_starting_frame', 'external_file')
        end
    end
    function set.format(obj, val)
        obj.format = obj.validate_format(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'numeric', val);
        types.util.validateShape('data', {[Inf,Inf,Inf,Inf], [Inf,Inf,Inf]}, val)
    end
    function val = validate_device(obj, val)
        if isa(val, 'types.untyped.SoftLink')
            if isprop(val, 'target')
                types.util.checkDtype('device', 'types.core.Device', val.target);
            end
        else
            val = types.util.checkDtype('device', 'types.core.Device', val);
            if ~isempty(val)
                val = types.untyped.SoftLink(val);
            end
        end
    end
    function val = validate_dimension(obj, val)
        val = types.util.checkDtype('dimension', 'int32', val);
        types.util.validateShape('dimension', {[Inf]}, val)
    end
    function val = validate_external_file(obj, val)
        val = types.util.checkDtype('external_file', 'char', val);
        types.util.validateShape('external_file', {[Inf]}, val)
    end
    function val = validate_external_file_starting_frame(obj, val)
        val = types.util.checkDtype('external_file_starting_frame', 'int32', val);
        types.util.validateShape('external_file_starting_frame', {[Inf]}, val)
    end
    function val = validate_format(obj, val)
        val = types.util.checkDtype('format', 'char', val);
        types.util.validateShape('format', {[1]}, val)
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.TimeSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.device)
            refs = obj.device.export(fid, [fullpath '/device'], refs);
        end
        if ~isempty(obj.dimension)
            if startsWith(class(obj.dimension), 'types.untyped.')
                refs = obj.dimension.export(fid, [fullpath '/dimension'], refs);
            elseif ~isempty(obj.dimension)
                io.writeDataset(fid, [fullpath '/dimension'], obj.dimension, 'forceArray');
            end
        end
        if ~isempty(obj.external_file)
            if startsWith(class(obj.external_file), 'types.untyped.')
                refs = obj.external_file.export(fid, [fullpath '/external_file'], refs);
            elseif ~isempty(obj.external_file)
                io.writeDataset(fid, [fullpath '/external_file'], obj.external_file, 'forceArray');
            end
        end
        if ~isempty(obj.external_file) && ~isa(obj.external_file, 'types.untyped.SoftLink') && ~isa(obj.external_file, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/external_file/starting_frame'], obj.external_file_starting_frame, 'forceArray');
        elseif isempty(obj.external_file) && ~isempty(obj.external_file_starting_frame)
            obj.warnIfPropertyAttributeNotExported('external_file_starting_frame', 'external_file', fullpath)
        end
        if ~isempty(obj.external_file) && isempty(obj.external_file_starting_frame)
            obj.throwErrorIfRequiredDependencyMissing('external_file_starting_frame', 'external_file', fullpath)
        end
        if ~isempty(obj.format)
            if startsWith(class(obj.format), 'types.untyped.')
                refs = obj.format.export(fid, [fullpath '/format'], refs);
            elseif ~isempty(obj.format)
                io.writeDataset(fid, [fullpath '/format'], obj.format);
            end
        end
    end
    %% CUSTOM CONSTRAINTS
    function checkCustomConstraint(obj)
        if ~isempty(obj.external_file) && isempty(obj.data), ...
            obj.data = nan(1,1,2);
        end
    end
end

end