classdef TwoPhotonSeries < types.core.ImageSeries & types.untyped.GroupClass
% TWOPHOTONSERIES - Image stack recorded over time from 2-photon microscope.
%
% Required Properties:
%  data, data_unit, imaging_plane


% REQUIRED PROPERTIES
properties
    imaging_plane; % REQUIRED ImagingPlane
end
% OPTIONAL PROPERTIES
properties
    field_of_view; %  (single) Width, height and depth of image, or imaged area, in meters.
    pmt_gain; %  (single) Photomultiplier gain.
    scan_line_rate; %  (single) Lines imaged per second. This is also stored in /general/optophysiology but is kept here as it is useful information for analysis, and so good to be stored w/ the actual data.
end

methods
    function obj = TwoPhotonSeries(varargin)
        % TWOPHOTONSERIES - Constructor for TwoPhotonSeries
        %
        % Syntax:
        %  twoPhotonSeries = types.core.TWOPHOTONSERIES() creates a TwoPhotonSeries object with unset property values.
        %
        %  twoPhotonSeries = types.core.TWOPHOTONSERIES(Name, Value) creates a TwoPhotonSeries object where one or more property values are specified using name-value pairs.
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
        %  - field_of_view (single) - Width, height and depth of image, or imaged area, in meters.
        %
        %  - format (char) - Format of image. If this is 'external', then the attribute 'external_file' contains the path information to the image files. If this is 'raw', then the raw (single-channel) binary data is stored in the 'data' dataset. If this attribute is not present, then the default format='raw' case is assumed.
        %
        %  - imaging_plane (ImagingPlane) - Link to ImagingPlane object from which this TimeSeries data was generated.
        %
        %  - pmt_gain (single) - Photomultiplier gain.
        %
        %  - scan_line_rate (single) - Lines imaged per second. This is also stored in /general/optophysiology but is kept here as it is useful information for analysis, and so good to be stored w/ the actual data.
        %
        %  - starting_time (double) - Timestamp of the first sample in seconds. When timestamps are uniformly spaced, the timestamp of the first sample can be specified and all subsequent ones calculated from the sampling rate attribute.
        %
        %  - starting_time_rate (single) - Sampling rate, in Hz.
        %
        %  - timestamps (double) - Timestamps for samples stored in data, in seconds, relative to the common experiment master-clock stored in NWBFile.timestamps_reference_time.
        %
        % Output Arguments:
        %  - twoPhotonSeries (types.core.TwoPhotonSeries) - A TwoPhotonSeries object
        
        obj = obj@types.core.ImageSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'field_of_view',[]);
        addParameter(p, 'imaging_plane',[]);
        addParameter(p, 'pmt_gain',[]);
        addParameter(p, 'scan_line_rate',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.field_of_view = p.Results.field_of_view;
        obj.imaging_plane = p.Results.imaging_plane;
        obj.pmt_gain = p.Results.pmt_gain;
        obj.scan_line_rate = p.Results.scan_line_rate;
        if strcmp(class(obj), 'types.core.TwoPhotonSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.field_of_view(obj, val)
        obj.field_of_view = obj.validate_field_of_view(val);
    end
    function set.imaging_plane(obj, val)
        obj.imaging_plane = obj.validate_imaging_plane(val);
    end
    function set.pmt_gain(obj, val)
        obj.pmt_gain = obj.validate_pmt_gain(val);
    end
    function set.scan_line_rate(obj, val)
        obj.scan_line_rate = obj.validate_scan_line_rate(val);
    end
    %% VALIDATORS
    
    function val = validate_field_of_view(obj, val)
        val = types.util.checkDtype('field_of_view', 'single', val);
        types.util.validateShape('field_of_view', {[3], [2]}, val)
    end
    function val = validate_imaging_plane(obj, val)
        if isa(val, 'types.untyped.SoftLink')
            if isprop(val, 'target')
                types.util.checkDtype('imaging_plane', 'types.core.ImagingPlane', val.target);
            end
        else
            val = types.util.checkDtype('imaging_plane', 'types.core.ImagingPlane', val);
            if ~isempty(val)
                val = types.untyped.SoftLink(val);
            end
        end
    end
    function val = validate_pmt_gain(obj, val)
        val = types.util.checkDtype('pmt_gain', 'single', val);
        types.util.validateShape('pmt_gain', {[1]}, val)
    end
    function val = validate_scan_line_rate(obj, val)
        val = types.util.checkDtype('scan_line_rate', 'single', val);
        types.util.validateShape('scan_line_rate', {[1]}, val)
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.ImageSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.field_of_view)
            if startsWith(class(obj.field_of_view), 'types.untyped.')
                refs = obj.field_of_view.export(fid, [fullpath '/field_of_view'], refs);
            elseif ~isempty(obj.field_of_view)
                io.writeDataset(fid, [fullpath '/field_of_view'], obj.field_of_view, 'forceArray');
            end
        end
        refs = obj.imaging_plane.export(fid, [fullpath '/imaging_plane'], refs);
        if ~isempty(obj.pmt_gain)
            io.writeAttribute(fid, [fullpath '/pmt_gain'], obj.pmt_gain);
        end
        if ~isempty(obj.scan_line_rate)
            io.writeAttribute(fid, [fullpath '/scan_line_rate'], obj.scan_line_rate);
        end
    end
end

end