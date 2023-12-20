classdef ImagingRetinotopy < types.core.NWBDataInterface & types.untyped.GroupClass
% IMAGINGRETINOTOPY Intrinsic signal optical imaging or widefield imaging for measuring retinotopy. Stores orthogonal maps (e.g., altitude/azimuth; radius/theta) of responses to specific stimuli and a combined polarity map from which to identify visual areas. This group does not store the raw responses imaged during retinotopic mapping or the stimuli presented, but rather the resulting phase and power maps after applying a Fourier transform on the averaged responses. Note: for data consistency, all images and arrays are stored in the format [row][column] and [row, col], which equates to [y][x]. Field of view and dimension arrays may appear backward (i.e., y before x).


% REQUIRED PROPERTIES
properties
    axis_1_phase_map; % REQUIRED (single) Phase response to stimulus on the first measured axis.
    axis_2_phase_map; % REQUIRED (single) Phase response to stimulus on the second measured axis.
    axis_descriptions; % REQUIRED (char) Two-element array describing the contents of the two response axis fields. Description should be something like ['altitude', 'azimuth'] or '['radius', 'theta'].
    vasculature_image; % REQUIRED (uint16) Gray-scale anatomical image of cortical surface. Array structure: [rows][columns]
end
% OPTIONAL PROPERTIES
properties
    axis_1_phase_map_dimension; %  (int32) Number of rows and columns in the image. NOTE: row, column representation is equivalent to height, width.
    axis_1_phase_map_field_of_view; %  (single) Size of viewing area, in meters.
    axis_1_phase_map_unit; %  (char) Unit that axis data is stored in (e.g., degrees).
    axis_1_power_map; %  (single) Power response on the first measured axis. Response is scaled so 0.0 is no power in the response and 1.0 is maximum relative power.
    axis_1_power_map_dimension; %  (int32) Number of rows and columns in the image. NOTE: row, column representation is equivalent to height, width.
    axis_1_power_map_field_of_view; %  (single) Size of viewing area, in meters.
    axis_1_power_map_unit; %  (char) Unit that axis data is stored in (e.g., degrees).
    axis_2_phase_map_dimension; %  (int32) Number of rows and columns in the image. NOTE: row, column representation is equivalent to height, width.
    axis_2_phase_map_field_of_view; %  (single) Size of viewing area, in meters.
    axis_2_phase_map_unit; %  (char) Unit that axis data is stored in (e.g., degrees).
    axis_2_power_map; %  (single) Power response on the second measured axis. Response is scaled so 0.0 is no power in the response and 1.0 is maximum relative power.
    axis_2_power_map_dimension; %  (int32) Number of rows and columns in the image. NOTE: row, column representation is equivalent to height, width.
    axis_2_power_map_field_of_view; %  (single) Size of viewing area, in meters.
    axis_2_power_map_unit; %  (char) Unit that axis data is stored in (e.g., degrees).
    focal_depth_image; %  (uint16) Gray-scale image taken with same settings/parameters (e.g., focal depth, wavelength) as data collection. Array format: [rows][columns].
    focal_depth_image_bits_per_pixel; %  (int32) Number of bits used to represent each value. This is necessary to determine maximum (white) pixel value.
    focal_depth_image_dimension; %  (int32) Number of rows and columns in the image. NOTE: row, column representation is equivalent to height, width.
    focal_depth_image_field_of_view; %  (single) Size of viewing area, in meters.
    focal_depth_image_focal_depth; %  (single) Focal depth offset, in meters.
    focal_depth_image_format; %  (char) Format of image. Right now only 'raw' is supported.
    sign_map; %  (single) Sine of the angle between the direction of the gradient in axis_1 and axis_2.
    sign_map_dimension; %  (int32) Number of rows and columns in the image. NOTE: row, column representation is equivalent to height, width.
    sign_map_field_of_view; %  (single) Size of viewing area, in meters.
    vasculature_image_bits_per_pixel; %  (int32) Number of bits used to represent each value. This is necessary to determine maximum (white) pixel value
    vasculature_image_dimension; %  (int32) Number of rows and columns in the image. NOTE: row, column representation is equivalent to height, width.
    vasculature_image_field_of_view; %  (single) Size of viewing area, in meters.
    vasculature_image_format; %  (char) Format of image. Right now only 'raw' is supported.
end

methods
    function obj = ImagingRetinotopy(varargin)
        % IMAGINGRETINOTOPY Constructor for ImagingRetinotopy
        obj = obj@types.core.NWBDataInterface(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'axis_1_phase_map',[]);
        addParameter(p, 'axis_1_phase_map_dimension',[]);
        addParameter(p, 'axis_1_phase_map_field_of_view',[]);
        addParameter(p, 'axis_1_phase_map_unit',[]);
        addParameter(p, 'axis_1_power_map',[]);
        addParameter(p, 'axis_1_power_map_dimension',[]);
        addParameter(p, 'axis_1_power_map_field_of_view',[]);
        addParameter(p, 'axis_1_power_map_unit',[]);
        addParameter(p, 'axis_2_phase_map',[]);
        addParameter(p, 'axis_2_phase_map_dimension',[]);
        addParameter(p, 'axis_2_phase_map_field_of_view',[]);
        addParameter(p, 'axis_2_phase_map_unit',[]);
        addParameter(p, 'axis_2_power_map',[]);
        addParameter(p, 'axis_2_power_map_dimension',[]);
        addParameter(p, 'axis_2_power_map_field_of_view',[]);
        addParameter(p, 'axis_2_power_map_unit',[]);
        addParameter(p, 'axis_descriptions',[]);
        addParameter(p, 'focal_depth_image',[]);
        addParameter(p, 'focal_depth_image_bits_per_pixel',[]);
        addParameter(p, 'focal_depth_image_dimension',[]);
        addParameter(p, 'focal_depth_image_field_of_view',[]);
        addParameter(p, 'focal_depth_image_focal_depth',[]);
        addParameter(p, 'focal_depth_image_format',[]);
        addParameter(p, 'sign_map',[]);
        addParameter(p, 'sign_map_dimension',[]);
        addParameter(p, 'sign_map_field_of_view',[]);
        addParameter(p, 'vasculature_image',[]);
        addParameter(p, 'vasculature_image_bits_per_pixel',[]);
        addParameter(p, 'vasculature_image_dimension',[]);
        addParameter(p, 'vasculature_image_field_of_view',[]);
        addParameter(p, 'vasculature_image_format',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.axis_1_phase_map = p.Results.axis_1_phase_map;
        obj.axis_1_phase_map_dimension = p.Results.axis_1_phase_map_dimension;
        obj.axis_1_phase_map_field_of_view = p.Results.axis_1_phase_map_field_of_view;
        obj.axis_1_phase_map_unit = p.Results.axis_1_phase_map_unit;
        obj.axis_1_power_map = p.Results.axis_1_power_map;
        obj.axis_1_power_map_dimension = p.Results.axis_1_power_map_dimension;
        obj.axis_1_power_map_field_of_view = p.Results.axis_1_power_map_field_of_view;
        obj.axis_1_power_map_unit = p.Results.axis_1_power_map_unit;
        obj.axis_2_phase_map = p.Results.axis_2_phase_map;
        obj.axis_2_phase_map_dimension = p.Results.axis_2_phase_map_dimension;
        obj.axis_2_phase_map_field_of_view = p.Results.axis_2_phase_map_field_of_view;
        obj.axis_2_phase_map_unit = p.Results.axis_2_phase_map_unit;
        obj.axis_2_power_map = p.Results.axis_2_power_map;
        obj.axis_2_power_map_dimension = p.Results.axis_2_power_map_dimension;
        obj.axis_2_power_map_field_of_view = p.Results.axis_2_power_map_field_of_view;
        obj.axis_2_power_map_unit = p.Results.axis_2_power_map_unit;
        obj.axis_descriptions = p.Results.axis_descriptions;
        obj.focal_depth_image = p.Results.focal_depth_image;
        obj.focal_depth_image_bits_per_pixel = p.Results.focal_depth_image_bits_per_pixel;
        obj.focal_depth_image_dimension = p.Results.focal_depth_image_dimension;
        obj.focal_depth_image_field_of_view = p.Results.focal_depth_image_field_of_view;
        obj.focal_depth_image_focal_depth = p.Results.focal_depth_image_focal_depth;
        obj.focal_depth_image_format = p.Results.focal_depth_image_format;
        obj.sign_map = p.Results.sign_map;
        obj.sign_map_dimension = p.Results.sign_map_dimension;
        obj.sign_map_field_of_view = p.Results.sign_map_field_of_view;
        obj.vasculature_image = p.Results.vasculature_image;
        obj.vasculature_image_bits_per_pixel = p.Results.vasculature_image_bits_per_pixel;
        obj.vasculature_image_dimension = p.Results.vasculature_image_dimension;
        obj.vasculature_image_field_of_view = p.Results.vasculature_image_field_of_view;
        obj.vasculature_image_format = p.Results.vasculature_image_format;
        if strcmp(class(obj), 'types.core.ImagingRetinotopy')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.axis_1_phase_map(obj, val)
        obj.axis_1_phase_map = obj.validate_axis_1_phase_map(val);
    end
    function set.axis_1_phase_map_dimension(obj, val)
        obj.axis_1_phase_map_dimension = obj.validate_axis_1_phase_map_dimension(val);
    end
    function set.axis_1_phase_map_field_of_view(obj, val)
        obj.axis_1_phase_map_field_of_view = obj.validate_axis_1_phase_map_field_of_view(val);
    end
    function set.axis_1_phase_map_unit(obj, val)
        obj.axis_1_phase_map_unit = obj.validate_axis_1_phase_map_unit(val);
    end
    function set.axis_1_power_map(obj, val)
        obj.axis_1_power_map = obj.validate_axis_1_power_map(val);
    end
    function set.axis_1_power_map_dimension(obj, val)
        obj.axis_1_power_map_dimension = obj.validate_axis_1_power_map_dimension(val);
    end
    function set.axis_1_power_map_field_of_view(obj, val)
        obj.axis_1_power_map_field_of_view = obj.validate_axis_1_power_map_field_of_view(val);
    end
    function set.axis_1_power_map_unit(obj, val)
        obj.axis_1_power_map_unit = obj.validate_axis_1_power_map_unit(val);
    end
    function set.axis_2_phase_map(obj, val)
        obj.axis_2_phase_map = obj.validate_axis_2_phase_map(val);
    end
    function set.axis_2_phase_map_dimension(obj, val)
        obj.axis_2_phase_map_dimension = obj.validate_axis_2_phase_map_dimension(val);
    end
    function set.axis_2_phase_map_field_of_view(obj, val)
        obj.axis_2_phase_map_field_of_view = obj.validate_axis_2_phase_map_field_of_view(val);
    end
    function set.axis_2_phase_map_unit(obj, val)
        obj.axis_2_phase_map_unit = obj.validate_axis_2_phase_map_unit(val);
    end
    function set.axis_2_power_map(obj, val)
        obj.axis_2_power_map = obj.validate_axis_2_power_map(val);
    end
    function set.axis_2_power_map_dimension(obj, val)
        obj.axis_2_power_map_dimension = obj.validate_axis_2_power_map_dimension(val);
    end
    function set.axis_2_power_map_field_of_view(obj, val)
        obj.axis_2_power_map_field_of_view = obj.validate_axis_2_power_map_field_of_view(val);
    end
    function set.axis_2_power_map_unit(obj, val)
        obj.axis_2_power_map_unit = obj.validate_axis_2_power_map_unit(val);
    end
    function set.axis_descriptions(obj, val)
        obj.axis_descriptions = obj.validate_axis_descriptions(val);
    end
    function set.focal_depth_image(obj, val)
        obj.focal_depth_image = obj.validate_focal_depth_image(val);
    end
    function set.focal_depth_image_bits_per_pixel(obj, val)
        obj.focal_depth_image_bits_per_pixel = obj.validate_focal_depth_image_bits_per_pixel(val);
    end
    function set.focal_depth_image_dimension(obj, val)
        obj.focal_depth_image_dimension = obj.validate_focal_depth_image_dimension(val);
    end
    function set.focal_depth_image_field_of_view(obj, val)
        obj.focal_depth_image_field_of_view = obj.validate_focal_depth_image_field_of_view(val);
    end
    function set.focal_depth_image_focal_depth(obj, val)
        obj.focal_depth_image_focal_depth = obj.validate_focal_depth_image_focal_depth(val);
    end
    function set.focal_depth_image_format(obj, val)
        obj.focal_depth_image_format = obj.validate_focal_depth_image_format(val);
    end
    function set.sign_map(obj, val)
        obj.sign_map = obj.validate_sign_map(val);
    end
    function set.sign_map_dimension(obj, val)
        obj.sign_map_dimension = obj.validate_sign_map_dimension(val);
    end
    function set.sign_map_field_of_view(obj, val)
        obj.sign_map_field_of_view = obj.validate_sign_map_field_of_view(val);
    end
    function set.vasculature_image(obj, val)
        obj.vasculature_image = obj.validate_vasculature_image(val);
    end
    function set.vasculature_image_bits_per_pixel(obj, val)
        obj.vasculature_image_bits_per_pixel = obj.validate_vasculature_image_bits_per_pixel(val);
    end
    function set.vasculature_image_dimension(obj, val)
        obj.vasculature_image_dimension = obj.validate_vasculature_image_dimension(val);
    end
    function set.vasculature_image_field_of_view(obj, val)
        obj.vasculature_image_field_of_view = obj.validate_vasculature_image_field_of_view(val);
    end
    function set.vasculature_image_format(obj, val)
        obj.vasculature_image_format = obj.validate_vasculature_image_format(val);
    end
    %% VALIDATORS
    
    function val = validate_axis_1_phase_map(obj, val)
        val = types.util.checkDtype('axis_1_phase_map', 'single', val);
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
        validshapes = {[Inf,Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_axis_1_phase_map_dimension(obj, val)
        val = types.util.checkDtype('axis_1_phase_map_dimension', 'int32', val);
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
        validshapes = {[2]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_axis_1_phase_map_field_of_view(obj, val)
        val = types.util.checkDtype('axis_1_phase_map_field_of_view', 'single', val);
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
        validshapes = {[2]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_axis_1_phase_map_unit(obj, val)
        val = types.util.checkDtype('axis_1_phase_map_unit', 'char', val);
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
    function val = validate_axis_1_power_map(obj, val)
        val = types.util.checkDtype('axis_1_power_map', 'single', val);
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
        validshapes = {[Inf,Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_axis_1_power_map_dimension(obj, val)
        val = types.util.checkDtype('axis_1_power_map_dimension', 'int32', val);
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
        validshapes = {[2]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_axis_1_power_map_field_of_view(obj, val)
        val = types.util.checkDtype('axis_1_power_map_field_of_view', 'single', val);
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
        validshapes = {[2]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_axis_1_power_map_unit(obj, val)
        val = types.util.checkDtype('axis_1_power_map_unit', 'char', val);
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
    function val = validate_axis_2_phase_map(obj, val)
        val = types.util.checkDtype('axis_2_phase_map', 'single', val);
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
        validshapes = {[Inf,Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_axis_2_phase_map_dimension(obj, val)
        val = types.util.checkDtype('axis_2_phase_map_dimension', 'int32', val);
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
        validshapes = {[2]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_axis_2_phase_map_field_of_view(obj, val)
        val = types.util.checkDtype('axis_2_phase_map_field_of_view', 'single', val);
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
        validshapes = {[2]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_axis_2_phase_map_unit(obj, val)
        val = types.util.checkDtype('axis_2_phase_map_unit', 'char', val);
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
    function val = validate_axis_2_power_map(obj, val)
        val = types.util.checkDtype('axis_2_power_map', 'single', val);
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
        validshapes = {[Inf,Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_axis_2_power_map_dimension(obj, val)
        val = types.util.checkDtype('axis_2_power_map_dimension', 'int32', val);
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
        validshapes = {[2]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_axis_2_power_map_field_of_view(obj, val)
        val = types.util.checkDtype('axis_2_power_map_field_of_view', 'single', val);
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
        validshapes = {[2]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_axis_2_power_map_unit(obj, val)
        val = types.util.checkDtype('axis_2_power_map_unit', 'char', val);
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
    function val = validate_axis_descriptions(obj, val)
        val = types.util.checkDtype('axis_descriptions', 'char', val);
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
        validshapes = {[2]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_focal_depth_image(obj, val)
        val = types.util.checkDtype('focal_depth_image', 'uint16', val);
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
        validshapes = {[Inf,Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_focal_depth_image_bits_per_pixel(obj, val)
        val = types.util.checkDtype('focal_depth_image_bits_per_pixel', 'int32', val);
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
    function val = validate_focal_depth_image_dimension(obj, val)
        val = types.util.checkDtype('focal_depth_image_dimension', 'int32', val);
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
        validshapes = {[2]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_focal_depth_image_field_of_view(obj, val)
        val = types.util.checkDtype('focal_depth_image_field_of_view', 'single', val);
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
        validshapes = {[2]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_focal_depth_image_focal_depth(obj, val)
        val = types.util.checkDtype('focal_depth_image_focal_depth', 'single', val);
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
    function val = validate_focal_depth_image_format(obj, val)
        val = types.util.checkDtype('focal_depth_image_format', 'char', val);
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
    function val = validate_sign_map(obj, val)
        val = types.util.checkDtype('sign_map', 'single', val);
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
        validshapes = {[Inf,Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_sign_map_dimension(obj, val)
        val = types.util.checkDtype('sign_map_dimension', 'int32', val);
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
        validshapes = {[2]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_sign_map_field_of_view(obj, val)
        val = types.util.checkDtype('sign_map_field_of_view', 'single', val);
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
        validshapes = {[2]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_vasculature_image(obj, val)
        val = types.util.checkDtype('vasculature_image', 'uint16', val);
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
        validshapes = {[Inf,Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_vasculature_image_bits_per_pixel(obj, val)
        val = types.util.checkDtype('vasculature_image_bits_per_pixel', 'int32', val);
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
    function val = validate_vasculature_image_dimension(obj, val)
        val = types.util.checkDtype('vasculature_image_dimension', 'int32', val);
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
        validshapes = {[2]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_vasculature_image_field_of_view(obj, val)
        val = types.util.checkDtype('vasculature_image_field_of_view', 'single', val);
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
        validshapes = {[2]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_vasculature_image_format(obj, val)
        val = types.util.checkDtype('vasculature_image_format', 'char', val);
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
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if startsWith(class(obj.axis_1_phase_map), 'types.untyped.')
            refs = obj.axis_1_phase_map.export(fid, [fullpath '/axis_1_phase_map'], refs);
        elseif ~isempty(obj.axis_1_phase_map)
            io.writeDataset(fid, [fullpath '/axis_1_phase_map'], obj.axis_1_phase_map, 'forceArray');
        end
        if ~isempty(obj.axis_1_phase_map) && ~isa(obj.axis_1_phase_map, 'types.untyped.SoftLink') && ~isa(obj.axis_1_phase_map, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/axis_1_phase_map/dimension'], obj.axis_1_phase_map_dimension, 'forceArray');
        end
        if ~isempty(obj.axis_1_phase_map) && ~isa(obj.axis_1_phase_map, 'types.untyped.SoftLink') && ~isa(obj.axis_1_phase_map, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/axis_1_phase_map/field_of_view'], obj.axis_1_phase_map_field_of_view, 'forceArray');
        end
        if ~isempty(obj.axis_1_phase_map) && ~isa(obj.axis_1_phase_map, 'types.untyped.SoftLink') && ~isa(obj.axis_1_phase_map, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/axis_1_phase_map/unit'], obj.axis_1_phase_map_unit);
        end
        if ~isempty(obj.axis_1_power_map)
            if startsWith(class(obj.axis_1_power_map), 'types.untyped.')
                refs = obj.axis_1_power_map.export(fid, [fullpath '/axis_1_power_map'], refs);
            elseif ~isempty(obj.axis_1_power_map)
                io.writeDataset(fid, [fullpath '/axis_1_power_map'], obj.axis_1_power_map, 'forceArray');
            end
        end
        if ~isempty(obj.axis_1_power_map) && ~isa(obj.axis_1_power_map, 'types.untyped.SoftLink') && ~isa(obj.axis_1_power_map, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/axis_1_power_map/dimension'], obj.axis_1_power_map_dimension, 'forceArray');
        end
        if ~isempty(obj.axis_1_power_map) && ~isa(obj.axis_1_power_map, 'types.untyped.SoftLink') && ~isa(obj.axis_1_power_map, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/axis_1_power_map/field_of_view'], obj.axis_1_power_map_field_of_view, 'forceArray');
        end
        if ~isempty(obj.axis_1_power_map) && ~isa(obj.axis_1_power_map, 'types.untyped.SoftLink') && ~isa(obj.axis_1_power_map, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/axis_1_power_map/unit'], obj.axis_1_power_map_unit);
        end
        if startsWith(class(obj.axis_2_phase_map), 'types.untyped.')
            refs = obj.axis_2_phase_map.export(fid, [fullpath '/axis_2_phase_map'], refs);
        elseif ~isempty(obj.axis_2_phase_map)
            io.writeDataset(fid, [fullpath '/axis_2_phase_map'], obj.axis_2_phase_map, 'forceArray');
        end
        if ~isempty(obj.axis_2_phase_map) && ~isa(obj.axis_2_phase_map, 'types.untyped.SoftLink') && ~isa(obj.axis_2_phase_map, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/axis_2_phase_map/dimension'], obj.axis_2_phase_map_dimension, 'forceArray');
        end
        if ~isempty(obj.axis_2_phase_map) && ~isa(obj.axis_2_phase_map, 'types.untyped.SoftLink') && ~isa(obj.axis_2_phase_map, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/axis_2_phase_map/field_of_view'], obj.axis_2_phase_map_field_of_view, 'forceArray');
        end
        if ~isempty(obj.axis_2_phase_map) && ~isa(obj.axis_2_phase_map, 'types.untyped.SoftLink') && ~isa(obj.axis_2_phase_map, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/axis_2_phase_map/unit'], obj.axis_2_phase_map_unit);
        end
        if ~isempty(obj.axis_2_power_map)
            if startsWith(class(obj.axis_2_power_map), 'types.untyped.')
                refs = obj.axis_2_power_map.export(fid, [fullpath '/axis_2_power_map'], refs);
            elseif ~isempty(obj.axis_2_power_map)
                io.writeDataset(fid, [fullpath '/axis_2_power_map'], obj.axis_2_power_map, 'forceArray');
            end
        end
        if ~isempty(obj.axis_2_power_map) && ~isa(obj.axis_2_power_map, 'types.untyped.SoftLink') && ~isa(obj.axis_2_power_map, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/axis_2_power_map/dimension'], obj.axis_2_power_map_dimension, 'forceArray');
        end
        if ~isempty(obj.axis_2_power_map) && ~isa(obj.axis_2_power_map, 'types.untyped.SoftLink') && ~isa(obj.axis_2_power_map, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/axis_2_power_map/field_of_view'], obj.axis_2_power_map_field_of_view, 'forceArray');
        end
        if ~isempty(obj.axis_2_power_map) && ~isa(obj.axis_2_power_map, 'types.untyped.SoftLink') && ~isa(obj.axis_2_power_map, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/axis_2_power_map/unit'], obj.axis_2_power_map_unit);
        end
        if startsWith(class(obj.axis_descriptions), 'types.untyped.')
            refs = obj.axis_descriptions.export(fid, [fullpath '/axis_descriptions'], refs);
        elseif ~isempty(obj.axis_descriptions)
            io.writeDataset(fid, [fullpath '/axis_descriptions'], obj.axis_descriptions, 'forceArray');
        end
        if ~isempty(obj.focal_depth_image)
            if startsWith(class(obj.focal_depth_image), 'types.untyped.')
                refs = obj.focal_depth_image.export(fid, [fullpath '/focal_depth_image'], refs);
            elseif ~isempty(obj.focal_depth_image)
                io.writeDataset(fid, [fullpath '/focal_depth_image'], obj.focal_depth_image, 'forceArray');
            end
        end
        if ~isempty(obj.focal_depth_image) && ~isa(obj.focal_depth_image, 'types.untyped.SoftLink') && ~isa(obj.focal_depth_image, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/focal_depth_image/bits_per_pixel'], obj.focal_depth_image_bits_per_pixel);
        end
        if ~isempty(obj.focal_depth_image) && ~isa(obj.focal_depth_image, 'types.untyped.SoftLink') && ~isa(obj.focal_depth_image, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/focal_depth_image/dimension'], obj.focal_depth_image_dimension, 'forceArray');
        end
        if ~isempty(obj.focal_depth_image) && ~isa(obj.focal_depth_image, 'types.untyped.SoftLink') && ~isa(obj.focal_depth_image, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/focal_depth_image/field_of_view'], obj.focal_depth_image_field_of_view, 'forceArray');
        end
        if ~isempty(obj.focal_depth_image) && ~isa(obj.focal_depth_image, 'types.untyped.SoftLink') && ~isa(obj.focal_depth_image, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/focal_depth_image/focal_depth'], obj.focal_depth_image_focal_depth);
        end
        if ~isempty(obj.focal_depth_image) && ~isa(obj.focal_depth_image, 'types.untyped.SoftLink') && ~isa(obj.focal_depth_image, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/focal_depth_image/format'], obj.focal_depth_image_format);
        end
        if ~isempty(obj.sign_map)
            if startsWith(class(obj.sign_map), 'types.untyped.')
                refs = obj.sign_map.export(fid, [fullpath '/sign_map'], refs);
            elseif ~isempty(obj.sign_map)
                io.writeDataset(fid, [fullpath '/sign_map'], obj.sign_map, 'forceArray');
            end
        end
        if ~isempty(obj.sign_map) && ~isa(obj.sign_map, 'types.untyped.SoftLink') && ~isa(obj.sign_map, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/sign_map/dimension'], obj.sign_map_dimension, 'forceArray');
        end
        if ~isempty(obj.sign_map) && ~isa(obj.sign_map, 'types.untyped.SoftLink') && ~isa(obj.sign_map, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/sign_map/field_of_view'], obj.sign_map_field_of_view, 'forceArray');
        end
        if startsWith(class(obj.vasculature_image), 'types.untyped.')
            refs = obj.vasculature_image.export(fid, [fullpath '/vasculature_image'], refs);
        elseif ~isempty(obj.vasculature_image)
            io.writeDataset(fid, [fullpath '/vasculature_image'], obj.vasculature_image, 'forceArray');
        end
        if ~isempty(obj.vasculature_image) && ~isa(obj.vasculature_image, 'types.untyped.SoftLink') && ~isa(obj.vasculature_image, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/vasculature_image/bits_per_pixel'], obj.vasculature_image_bits_per_pixel);
        end
        if ~isempty(obj.vasculature_image) && ~isa(obj.vasculature_image, 'types.untyped.SoftLink') && ~isa(obj.vasculature_image, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/vasculature_image/dimension'], obj.vasculature_image_dimension, 'forceArray');
        end
        if ~isempty(obj.vasculature_image) && ~isa(obj.vasculature_image, 'types.untyped.SoftLink') && ~isa(obj.vasculature_image, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/vasculature_image/field_of_view'], obj.vasculature_image_field_of_view, 'forceArray');
        end
        if ~isempty(obj.vasculature_image) && ~isa(obj.vasculature_image, 'types.untyped.SoftLink') && ~isa(obj.vasculature_image, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/vasculature_image/format'], obj.vasculature_image_format);
        end
    end
end

end