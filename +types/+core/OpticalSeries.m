classdef OpticalSeries < types.core.ImageSeries & types.untyped.GroupClass
% OPTICALSERIES Image data that is presented or recorded. A stimulus template movie will be stored only as an image. When the image is presented as stimulus, additional data is required, such as field of view (e.g., how much of the visual field the image covers, or how what is the area of the target being imaged). If the OpticalSeries represents acquired imaging data, orientation is also important.


% OPTIONAL PROPERTIES
properties
    distance; %  (single) Distance from camera/monitor to target/eye.
    field_of_view; %  (single) Width, height and depth of image, or imaged area, in meters.
    orientation; %  (char) Description of image relative to some reference frame (e.g., which way is up). Must also specify frame of reference.
end

methods
    function obj = OpticalSeries(varargin)
        % OPTICALSERIES Constructor for OpticalSeries
        obj = obj@types.core.ImageSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'data',[]);
        addParameter(p, 'distance',[]);
        addParameter(p, 'field_of_view',[]);
        addParameter(p, 'orientation',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.data = p.Results.data;
        obj.distance = p.Results.distance;
        obj.field_of_view = p.Results.field_of_view;
        obj.orientation = p.Results.orientation;
        if strcmp(class(obj), 'types.core.OpticalSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.distance(obj, val)
        obj.distance = obj.validate_distance(val);
    end
    function set.field_of_view(obj, val)
        obj.field_of_view = obj.validate_field_of_view(val);
    end
    function set.orientation(obj, val)
        obj.orientation = obj.validate_orientation(val);
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
        validshapes = {[3,Inf,Inf,Inf], [Inf,Inf,Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_distance(obj, val)
        val = types.util.checkDtype('distance', 'single', val);
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
    function val = validate_field_of_view(obj, val)
        val = types.util.checkDtype('field_of_view', 'single', val);
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
        validshapes = {[3], [2]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_orientation(obj, val)
        val = types.util.checkDtype('orientation', 'char', val);
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
        refs = export@types.core.ImageSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.distance)
            if startsWith(class(obj.distance), 'types.untyped.')
                refs = obj.distance.export(fid, [fullpath '/distance'], refs);
            elseif ~isempty(obj.distance)
                io.writeDataset(fid, [fullpath '/distance'], obj.distance);
            end
        end
        if ~isempty(obj.field_of_view)
            if startsWith(class(obj.field_of_view), 'types.untyped.')
                refs = obj.field_of_view.export(fid, [fullpath '/field_of_view'], refs);
            elseif ~isempty(obj.field_of_view)
                io.writeDataset(fid, [fullpath '/field_of_view'], obj.field_of_view, 'forceArray');
            end
        end
        if ~isempty(obj.orientation)
            if startsWith(class(obj.orientation), 'types.untyped.')
                refs = obj.orientation.export(fid, [fullpath '/orientation'], refs);
            elseif ~isempty(obj.orientation)
                io.writeDataset(fid, [fullpath '/orientation'], obj.orientation);
            end
        end
    end
end

end