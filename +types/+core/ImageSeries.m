classdef ImageSeries < types.core.TimeSeries & types.untyped.GroupClass
% IMAGESERIES General image data that is common between acquisition and stimulus time series. Sometimes the image data is stored in the file in a raw format while other times it will be stored as a series of external image files in the host file system. The data field will either be binary data, if the data is stored in the NWB file, or empty, if the data is stored in an external image stack. [frame][x][y] or [frame][x][y][z].


% OPTIONAL PROPERTIES
properties
    device; %  Device
    dimension; %  (int32) Number of pixels on x, y, (and z) axes.
    external_file; %  (char) Paths to one or more external file(s). The field is only present if format='external'. This is only relevant if the image series is stored in the file system as one or more image file(s). This field should NOT be used if the image is stored in another NWB file and that file is linked to this file.
    external_file_starting_frame; %  (int32) Each external image may contain one or more consecutive frames of the full ImageSeries. This attribute serves as an index to indicate which frames each file contains, to faciliate random access. The 'starting_frame' attribute, hence, contains a list of frame numbers within the full ImageSeries of the first frame of each file listed in the parent 'external_file' dataset. Zero-based indexing is used (hence, the first element will always be zero). For example, if the 'external_file' dataset has three paths to files and the first file has 5 frames, the second file has 10 frames, and the third file has 20 frames, then this attribute will have values [0, 5, 15]. If there is a single external file that holds all of the frames of the ImageSeries (and so there is a single element in the 'external_file' dataset), then this attribute should have value [0].
    format; %  (char) Format of image. If this is 'external', then the attribute 'external_file' contains the path information to the image files. If this is 'raw', then the raw (single-channel) binary data is stored in the 'data' dataset. If this attribute is not present, then the default format='raw' case is assumed.
end

methods
    function obj = ImageSeries(varargin)
        % IMAGESERIES Constructor for ImageSeries
        obj = obj@types.core.TimeSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'data',[]);
        addParameter(p, 'device',[]);
        addParameter(p, 'dimension',[]);
        addParameter(p, 'external_file',[]);
        addParameter(p, 'external_file_starting_frame',[]);
        addParameter(p, 'format',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.data = p.Results.data;
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
    end
    function set.format(obj, val)
        obj.format = obj.validate_format(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'numeric', val);
        if isa(val, 'types.untyped.DataStub')
            if 1 == val.ndims
                valsz = [val.dims 1];
            else
                valsz = val.dims;
            end
        elseif istable(val)
            valsz = [height(val) 1];
        elseif ischar(val)
            valsz = [size(val, 1) 1];
        else
            valsz = size(val);
        end
        validshapes = {[Inf,Inf,Inf,Inf], [Inf,Inf,Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_device(obj, val)
        val = types.util.checkDtype('device', 'types.core.Device', val);
    end
    function val = validate_dimension(obj, val)
        val = types.util.checkDtype('dimension', 'int32', val);
        if isa(val, 'types.untyped.DataStub')
            if 1 == val.ndims
                valsz = [val.dims 1];
            else
                valsz = val.dims;
            end
        elseif istable(val)
            valsz = [height(val) 1];
        elseif ischar(val)
            valsz = [size(val, 1) 1];
        else
            valsz = size(val);
        end
        validshapes = {[Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_external_file(obj, val)
        val = types.util.checkDtype('external_file', 'char', val);
        if isa(val, 'types.untyped.DataStub')
            if 1 == val.ndims
                valsz = [val.dims 1];
            else
                valsz = val.dims;
            end
        elseif istable(val)
            valsz = [height(val) 1];
        elseif ischar(val)
            valsz = [size(val, 1) 1];
        else
            valsz = size(val);
        end
        validshapes = {[Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_external_file_starting_frame(obj, val)
        val = types.util.checkDtype('external_file_starting_frame', 'int32', val);
        if isa(val, 'types.untyped.DataStub')
            if 1 == val.ndims
                valsz = [val.dims 1];
            else
                valsz = val.dims;
            end
        elseif istable(val)
            valsz = [height(val) 1];
        elseif ischar(val)
            valsz = [size(val, 1) 1];
        else
            valsz = size(val);
        end
        validshapes = {[Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_format(obj, val)
        val = types.util.checkDtype('format', 'char', val);
        if isa(val, 'types.untyped.DataStub')
            if 1 == val.ndims
                valsz = [val.dims 1];
            else
                valsz = val.dims;
            end
        elseif istable(val)
            valsz = [height(val) 1];
        elseif ischar(val)
            valsz = [size(val, 1) 1];
        else
            valsz = size(val);
        end
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
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
        end
        if ~isempty(obj.format)
            if startsWith(class(obj.format), 'types.untyped.')
                refs = obj.format.export(fid, [fullpath '/format'], refs);
            elseif ~isempty(obj.format)
                io.writeDataset(fid, [fullpath '/format'], obj.format);
            end
        end
    end
end

end