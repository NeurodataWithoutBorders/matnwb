classdef ImagingPlane < types.core.NWBContainer & types.untyped.GroupClass
% IMAGINGPLANE - An imaging plane and its metadata.
%
% Required Properties:
%  device, excitation_lambda, indicator, location, opticalchannel


% REQUIRED PROPERTIES
properties
    device; % REQUIRED Device
    excitation_lambda; % REQUIRED (single) Excitation wavelength, in nm.
    indicator; % REQUIRED (char) Calcium indicator.
    location; % REQUIRED (char) Location of the imaging plane. Specify the area, layer, comments on estimation of area/layer, stereotaxic coordinates if in vivo, etc. Use standard atlas names for anatomical regions when possible.
    opticalchannel; % REQUIRED (OpticalChannel) An optical channel used to record from an imaging plane.
end
% OPTIONAL PROPERTIES
properties
    description; %  (char) Description of the imaging plane.
    grid_spacing; %  (single) Space between pixels in (x, y) or voxels in (x, y, z) directions, in the specified unit. Assumes imaging plane is a regular grid. See also reference_frame to interpret the grid.
    grid_spacing_unit = "meters"; %  (char) Measurement units for grid_spacing. The default value is 'meters'.
    imaging_rate; %  (single) Rate that images are acquired, in Hz. If the corresponding TimeSeries is present, the rate should be stored there instead.
    manifold; %  (single) DEPRECATED Physical position of each pixel. 'xyz' represents the position of the pixel relative to the defined coordinate space. Deprecated in favor of origin_coords and grid_spacing.
    manifold_conversion = 1; %  (single) Scalar to multiply each element in data to convert it to the specified 'unit'. If the data are stored in acquisition system units or other units that require a conversion to be interpretable, multiply the data by 'conversion' to convert the data to the specified 'unit'. e.g. if the data acquisition system stores values in this object as pixels from x = -500 to 499, y = -500 to 499 that correspond to a 2 m x 2 m range, then the 'conversion' multiplier to get from raw data acquisition pixel units to meters is 2/1000.
    manifold_unit = "meters"; %  (char) Base unit of measurement for working with the data. The default value is 'meters'.
    origin_coords; %  (single) Physical location of the first element of the imaging plane (0, 0) for 2-D data or (0, 0, 0) for 3-D data. See also reference_frame for what the physical location is relative to (e.g., bregma).
    origin_coords_unit = "meters"; %  (char) Measurement units for origin_coords. The default value is 'meters'.
    reference_frame; %  (char) Describes reference frame of origin_coords and grid_spacing. For example, this can be a text description of the anatomical location and orientation of the grid defined by origin_coords and grid_spacing or the vectors needed to transform or rotate the grid to a common anatomical axis (e.g., AP/DV/ML). This field is necessary to interpret origin_coords and grid_spacing. If origin_coords and grid_spacing are not present, then this field is not required. For example, if the microscope takes 10 x 10 x 2 images, where the first value of the data matrix (index (0, 0, 0)) corresponds to (-1.2, -0.6, -2) mm relative to bregma, the spacing between pixels is 0.2 mm in x, 0.2 mm in y and 0.5 mm in z, and larger numbers in x means more anterior, larger numbers in y means more rightward, and larger numbers in z means more ventral, then enter the following -- origin_coords = (-1.2, -0.6, -2) grid_spacing = (0.2, 0.2, 0.5) reference_frame = "Origin coordinates are relative to bregma. First dimension corresponds to anterior-posterior axis (larger index = more anterior). Second dimension corresponds to medial-lateral axis (larger index = more rightward). Third dimension corresponds to dorsal-ventral axis (larger index = more ventral)."
end

methods
    function obj = ImagingPlane(varargin)
        % IMAGINGPLANE - Constructor for ImagingPlane
        %
        % Syntax:
        %  imagingPlane = types.core.IMAGINGPLANE() creates a ImagingPlane object with unset property values.
        %
        %  imagingPlane = types.core.IMAGINGPLANE(Name, Value) creates a ImagingPlane object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - description (char) - Description of the imaging plane.
        %
        %  - device (Device) - Link to the Device object that was used to record from this electrode.
        %
        %  - excitation_lambda (single) - Excitation wavelength, in nm.
        %
        %  - grid_spacing (single) - Space between pixels in (x, y) or voxels in (x, y, z) directions, in the specified unit. Assumes imaging plane is a regular grid. See also reference_frame to interpret the grid.
        %
        %  - grid_spacing_unit (char) - Measurement units for grid_spacing. The default value is 'meters'.
        %
        %  - imaging_rate (single) - Rate that images are acquired, in Hz. If the corresponding TimeSeries is present, the rate should be stored there instead.
        %
        %  - indicator (char) - Calcium indicator.
        %
        %  - location (char) - Location of the imaging plane. Specify the area, layer, comments on estimation of area/layer, stereotaxic coordinates if in vivo, etc. Use standard atlas names for anatomical regions when possible.
        %
        %  - manifold (single) - DEPRECATED Physical position of each pixel. 'xyz' represents the position of the pixel relative to the defined coordinate space. Deprecated in favor of origin_coords and grid_spacing.
        %
        %  - manifold_conversion (single) - Scalar to multiply each element in data to convert it to the specified 'unit'. If the data are stored in acquisition system units or other units that require a conversion to be interpretable, multiply the data by 'conversion' to convert the data to the specified 'unit'. e.g. if the data acquisition system stores values in this object as pixels from x = -500 to 499, y = -500 to 499 that correspond to a 2 m x 2 m range, then the 'conversion' multiplier to get from raw data acquisition pixel units to meters is 2/1000.
        %
        %  - manifold_unit (char) - Base unit of measurement for working with the data. The default value is 'meters'.
        %
        %  - opticalchannel (OpticalChannel) - An optical channel used to record from an imaging plane.
        %
        %  - origin_coords (single) - Physical location of the first element of the imaging plane (0, 0) for 2-D data or (0, 0, 0) for 3-D data. See also reference_frame for what the physical location is relative to (e.g., bregma).
        %
        %  - origin_coords_unit (char) - Measurement units for origin_coords. The default value is 'meters'.
        %
        %  - reference_frame (char) - Describes reference frame of origin_coords and grid_spacing. For example, this can be a text description of the anatomical location and orientation of the grid defined by origin_coords and grid_spacing or the vectors needed to transform or rotate the grid to a common anatomical axis (e.g., AP/DV/ML). This field is necessary to interpret origin_coords and grid_spacing. If origin_coords and grid_spacing are not present, then this field is not required. For example, if the microscope takes 10 x 10 x 2 images, where the first value of the data matrix (index (0, 0, 0)) corresponds to (-1.2, -0.6, -2) mm relative to bregma, the spacing between pixels is 0.2 mm in x, 0.2 mm in y and 0.5 mm in z, and larger numbers in x means more anterior, larger numbers in y means more rightward, and larger numbers in z means more ventral, then enter the following -- origin_coords = (-1.2, -0.6, -2) grid_spacing = (0.2, 0.2, 0.5) reference_frame = "Origin coordinates are relative to bregma. First dimension corresponds to anterior-posterior axis (larger index = more anterior). Second dimension corresponds to medial-lateral axis (larger index = more rightward). Third dimension corresponds to dorsal-ventral axis (larger index = more ventral)."
        %
        % Output Arguments:
        %  - imagingPlane (types.core.ImagingPlane) - A ImagingPlane object
        
        varargin = [{'grid_spacing_unit' 'meters' 'manifold_conversion' types.util.correctType(1, 'single') 'manifold_unit' 'meters' 'origin_coords_unit' 'meters'} varargin];
        obj = obj@types.core.NWBContainer(varargin{:});
        [obj.opticalchannel, ivarargin] = types.util.parseConstrained(obj,'opticalchannel', 'types.core.OpticalChannel', varargin{:});
        varargin(ivarargin) = [];
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'description',[]);
        addParameter(p, 'device',[]);
        addParameter(p, 'excitation_lambda',[]);
        addParameter(p, 'grid_spacing',[]);
        addParameter(p, 'grid_spacing_unit',[]);
        addParameter(p, 'imaging_rate',[]);
        addParameter(p, 'indicator',[]);
        addParameter(p, 'location',[]);
        addParameter(p, 'manifold',[]);
        addParameter(p, 'manifold_conversion',[]);
        addParameter(p, 'manifold_unit',[]);
        addParameter(p, 'origin_coords',[]);
        addParameter(p, 'origin_coords_unit',[]);
        addParameter(p, 'reference_frame',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.description = p.Results.description;
        obj.device = p.Results.device;
        obj.excitation_lambda = p.Results.excitation_lambda;
        obj.grid_spacing = p.Results.grid_spacing;
        obj.grid_spacing_unit = p.Results.grid_spacing_unit;
        obj.imaging_rate = p.Results.imaging_rate;
        obj.indicator = p.Results.indicator;
        obj.location = p.Results.location;
        obj.manifold = p.Results.manifold;
        obj.manifold_conversion = p.Results.manifold_conversion;
        obj.manifold_unit = p.Results.manifold_unit;
        obj.origin_coords = p.Results.origin_coords;
        obj.origin_coords_unit = p.Results.origin_coords_unit;
        obj.reference_frame = p.Results.reference_frame;
        if strcmp(class(obj), 'types.core.ImagingPlane')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.description(obj, val)
        obj.description = obj.validate_description(val);
    end
    function set.device(obj, val)
        obj.device = obj.validate_device(val);
    end
    function set.excitation_lambda(obj, val)
        obj.excitation_lambda = obj.validate_excitation_lambda(val);
    end
    function set.grid_spacing(obj, val)
        obj.grid_spacing = obj.validate_grid_spacing(val);
    end
    function set.grid_spacing_unit(obj, val)
        obj.grid_spacing_unit = obj.validate_grid_spacing_unit(val);
        obj.postset_grid_spacing_unit()
    end
    function postset_grid_spacing_unit(obj)
        if isempty(obj.grid_spacing) && ~isempty(obj.grid_spacing_unit)
            obj.warnIfAttributeDependencyMissing('grid_spacing_unit', 'grid_spacing')
        end
    end
    function set.imaging_rate(obj, val)
        obj.imaging_rate = obj.validate_imaging_rate(val);
    end
    function set.indicator(obj, val)
        obj.indicator = obj.validate_indicator(val);
    end
    function set.location(obj, val)
        obj.location = obj.validate_location(val);
    end
    function set.manifold(obj, val)
        obj.manifold = obj.validate_manifold(val);
    end
    function set.manifold_conversion(obj, val)
        obj.manifold_conversion = obj.validate_manifold_conversion(val);
        obj.postset_manifold_conversion()
    end
    function postset_manifold_conversion(obj)
        if isempty(obj.manifold) && ~isempty(obj.manifold_conversion)
            obj.warnIfAttributeDependencyMissing('manifold_conversion', 'manifold')
        end
    end
    function set.manifold_unit(obj, val)
        obj.manifold_unit = obj.validate_manifold_unit(val);
        obj.postset_manifold_unit()
    end
    function postset_manifold_unit(obj)
        if isempty(obj.manifold) && ~isempty(obj.manifold_unit)
            obj.warnIfAttributeDependencyMissing('manifold_unit', 'manifold')
        end
    end
    function set.opticalchannel(obj, val)
        obj.opticalchannel = obj.validate_opticalchannel(val);
    end
    function set.origin_coords(obj, val)
        obj.origin_coords = obj.validate_origin_coords(val);
    end
    function set.origin_coords_unit(obj, val)
        obj.origin_coords_unit = obj.validate_origin_coords_unit(val);
        obj.postset_origin_coords_unit()
    end
    function postset_origin_coords_unit(obj)
        if isempty(obj.origin_coords) && ~isempty(obj.origin_coords_unit)
            obj.warnIfAttributeDependencyMissing('origin_coords_unit', 'origin_coords')
        end
    end
    function set.reference_frame(obj, val)
        obj.reference_frame = obj.validate_reference_frame(val);
    end
    %% VALIDATORS
    
    function val = validate_description(obj, val)
        val = types.util.checkDtype('description', 'char', val);
        types.util.validateShape('description', {[1]}, val)
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
    function val = validate_excitation_lambda(obj, val)
        val = types.util.checkDtype('excitation_lambda', 'single', val);
        types.util.validateShape('excitation_lambda', {[1]}, val)
    end
    function val = validate_grid_spacing(obj, val)
        val = types.util.checkDtype('grid_spacing', 'single', val);
        types.util.validateShape('grid_spacing', {[3], [2]}, val)
    end
    function val = validate_grid_spacing_unit(obj, val)
        val = types.util.checkDtype('grid_spacing_unit', 'char', val);
        types.util.validateShape('grid_spacing_unit', {[1]}, val)
    end
    function val = validate_imaging_rate(obj, val)
        val = types.util.checkDtype('imaging_rate', 'single', val);
        types.util.validateShape('imaging_rate', {[1]}, val)
    end
    function val = validate_indicator(obj, val)
        val = types.util.checkDtype('indicator', 'char', val);
        types.util.validateShape('indicator', {[1]}, val)
    end
    function val = validate_location(obj, val)
        val = types.util.checkDtype('location', 'char', val);
        types.util.validateShape('location', {[1]}, val)
    end
    function val = validate_manifold(obj, val)
        val = types.util.checkDtype('manifold', 'single', val);
        types.util.validateShape('manifold', {[3,Inf,Inf,Inf], [3,Inf,Inf]}, val)
    end
    function val = validate_manifold_conversion(obj, val)
        val = types.util.checkDtype('manifold_conversion', 'single', val);
        types.util.validateShape('manifold_conversion', {[1]}, val)
    end
    function val = validate_manifold_unit(obj, val)
        val = types.util.checkDtype('manifold_unit', 'char', val);
        types.util.validateShape('manifold_unit', {[1]}, val)
    end
    function val = validate_opticalchannel(obj, val)
        namedprops = struct();
        constrained = {'types.core.OpticalChannel'};
        types.util.checkSet('opticalchannel', namedprops, constrained, val);
    end
    function val = validate_origin_coords(obj, val)
        val = types.util.checkDtype('origin_coords', 'single', val);
        types.util.validateShape('origin_coords', {[3], [2]}, val)
    end
    function val = validate_origin_coords_unit(obj, val)
        val = types.util.checkDtype('origin_coords_unit', 'char', val);
        types.util.validateShape('origin_coords_unit', {[1]}, val)
    end
    function val = validate_reference_frame(obj, val)
        val = types.util.checkDtype('reference_frame', 'char', val);
        types.util.validateShape('reference_frame', {[1]}, val)
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBContainer(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.description)
            if startsWith(class(obj.description), 'types.untyped.')
                refs = obj.description.export(fid, [fullpath '/description'], refs);
            elseif ~isempty(obj.description)
                io.writeDataset(fid, [fullpath '/description'], obj.description);
            end
        end
        refs = obj.device.export(fid, [fullpath '/device'], refs);
        if startsWith(class(obj.excitation_lambda), 'types.untyped.')
            refs = obj.excitation_lambda.export(fid, [fullpath '/excitation_lambda'], refs);
        elseif ~isempty(obj.excitation_lambda)
            io.writeDataset(fid, [fullpath '/excitation_lambda'], obj.excitation_lambda);
        end
        if ~isempty(obj.grid_spacing)
            if startsWith(class(obj.grid_spacing), 'types.untyped.')
                refs = obj.grid_spacing.export(fid, [fullpath '/grid_spacing'], refs);
            elseif ~isempty(obj.grid_spacing)
                io.writeDataset(fid, [fullpath '/grid_spacing'], obj.grid_spacing, 'forceArray');
            end
        end
        if ~isempty(obj.grid_spacing) && ~isa(obj.grid_spacing, 'types.untyped.SoftLink') && ~isa(obj.grid_spacing, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/grid_spacing/unit'], obj.grid_spacing_unit);
        elseif isempty(obj.grid_spacing) && ~isempty(obj.grid_spacing_unit)
            obj.warnIfPropertyAttributeNotExported('grid_spacing_unit', 'grid_spacing', fullpath)
        end
        if ~isempty(obj.grid_spacing) && isempty(obj.grid_spacing_unit)
            obj.throwErrorIfRequiredDependencyMissing('grid_spacing_unit', 'grid_spacing', fullpath)
        end
        if ~isempty(obj.imaging_rate)
            if startsWith(class(obj.imaging_rate), 'types.untyped.')
                refs = obj.imaging_rate.export(fid, [fullpath '/imaging_rate'], refs);
            elseif ~isempty(obj.imaging_rate)
                io.writeDataset(fid, [fullpath '/imaging_rate'], obj.imaging_rate);
            end
        end
        if startsWith(class(obj.indicator), 'types.untyped.')
            refs = obj.indicator.export(fid, [fullpath '/indicator'], refs);
        elseif ~isempty(obj.indicator)
            io.writeDataset(fid, [fullpath '/indicator'], obj.indicator);
        end
        if startsWith(class(obj.location), 'types.untyped.')
            refs = obj.location.export(fid, [fullpath '/location'], refs);
        elseif ~isempty(obj.location)
            io.writeDataset(fid, [fullpath '/location'], obj.location);
        end
        if ~isempty(obj.manifold)
            if startsWith(class(obj.manifold), 'types.untyped.')
                refs = obj.manifold.export(fid, [fullpath '/manifold'], refs);
            elseif ~isempty(obj.manifold)
                io.writeDataset(fid, [fullpath '/manifold'], obj.manifold, 'forceArray');
            end
        end
        if ~isempty(obj.manifold) && ~isa(obj.manifold, 'types.untyped.SoftLink') && ~isa(obj.manifold, 'types.untyped.ExternalLink') && ~isempty(obj.manifold_conversion)
            io.writeAttribute(fid, [fullpath '/manifold/conversion'], obj.manifold_conversion);
        end
        if ~isempty(obj.manifold) && ~isa(obj.manifold, 'types.untyped.SoftLink') && ~isa(obj.manifold, 'types.untyped.ExternalLink') && ~isempty(obj.manifold_unit)
            io.writeAttribute(fid, [fullpath '/manifold/unit'], obj.manifold_unit);
        end
        refs = obj.opticalchannel.export(fid, fullpath, refs);
        if ~isempty(obj.origin_coords)
            if startsWith(class(obj.origin_coords), 'types.untyped.')
                refs = obj.origin_coords.export(fid, [fullpath '/origin_coords'], refs);
            elseif ~isempty(obj.origin_coords)
                io.writeDataset(fid, [fullpath '/origin_coords'], obj.origin_coords, 'forceArray');
            end
        end
        if ~isempty(obj.origin_coords) && ~isa(obj.origin_coords, 'types.untyped.SoftLink') && ~isa(obj.origin_coords, 'types.untyped.ExternalLink')
            io.writeAttribute(fid, [fullpath '/origin_coords/unit'], obj.origin_coords_unit);
        elseif isempty(obj.origin_coords) && ~isempty(obj.origin_coords_unit)
            obj.warnIfPropertyAttributeNotExported('origin_coords_unit', 'origin_coords', fullpath)
        end
        if ~isempty(obj.origin_coords) && isempty(obj.origin_coords_unit)
            obj.throwErrorIfRequiredDependencyMissing('origin_coords_unit', 'origin_coords', fullpath)
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