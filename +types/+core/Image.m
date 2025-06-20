classdef Image < types.core.NWBData & types.untyped.DatasetClass
% IMAGE - An abstract data type for an image. Shape can be 2-D (x, y), or 3-D where the third dimension can have three or four elements, e.g. (x, y, (r, g, b)) or (x, y, (r, g, b, a)).
%
% Required Properties:
%  data


% OPTIONAL PROPERTIES
properties
    description; %  (char) Description of the image.
    resolution; %  (single) Pixel resolution of the image, in pixels per centimeter.
end

methods
    function obj = Image(varargin)
        % IMAGE - Constructor for Image
        %
        % Syntax:
        %  image = types.core.IMAGE() creates a Image object with unset property values.
        %
        %  image = types.core.IMAGE(Name, Value) creates a Image object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - data (numeric) - No description
        %
        %  - description (char) - Description of the image.
        %
        %  - resolution (single) - Pixel resolution of the image, in pixels per centimeter.
        %
        % Output Arguments:
        %  - image (types.core.Image) - A Image object
        
        obj = obj@types.core.NWBData(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'description',[]);
        addParameter(p, 'resolution',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.description = p.Results.description;
        obj.resolution = p.Results.resolution;
        if strcmp(class(obj), 'types.core.Image')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.description(obj, val)
        obj.description = obj.validate_description(val);
    end
    function set.resolution(obj, val)
        obj.resolution = obj.validate_resolution(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'numeric', val);
    end
    function val = validate_description(obj, val)
        val = types.util.checkDtype('description', 'char', val);
        types.util.validateShape('description', {[1]}, val)
    end
    function val = validate_resolution(obj, val)
        val = types.util.checkDtype('resolution', 'single', val);
        types.util.validateShape('resolution', {[1]}, val)
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBData(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.description)
            io.writeAttribute(fid, [fullpath '/description'], obj.description);
        end
        if ~isempty(obj.resolution)
            io.writeAttribute(fid, [fullpath '/resolution'], obj.resolution);
        end
    end
end

end