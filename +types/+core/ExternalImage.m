classdef ExternalImage < types.core.BaseImage & types.untyped.DatasetClass
% EXTERNALIMAGE - A type for referencing an external image file. The single file path or URI to the external image file should be stored in the dataset. This type should NOT be used if the image is stored in another NWB file and that file is linked to this file.
%
% Required Properties:
%  data, image_format


% REQUIRED PROPERTIES
properties
    image_format; % REQUIRED (char) Common name of the image file format. Only widely readable, open file formats are allowed. Allowed values are "PNG", "JPEG", and "GIF".
end
% OPTIONAL PROPERTIES
properties
    image_mode; %  (char) Image mode (color mode) of the image, e.g., "RGB", "RGBA", "grayscale", and "LA".
end

methods
    function obj = ExternalImage(varargin)
        % EXTERNALIMAGE - Constructor for ExternalImage
        %
        % Syntax:
        %  externalImage = types.core.EXTERNALIMAGE() creates a ExternalImage object with unset property values.
        %
        %  externalImage = types.core.EXTERNALIMAGE(Name, Value) creates a ExternalImage object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - data (char) - No description
        %
        %  - description (char) - Description of the image.
        %
        %  - image_format (char) - Common name of the image file format. Only widely readable, open file formats are allowed. Allowed values are "PNG", "JPEG", and "GIF".
        %
        %  - image_mode (char) - Image mode (color mode) of the image, e.g., "RGB", "RGBA", "grayscale", and "LA".
        %
        % Output Arguments:
        %  - externalImage (types.core.ExternalImage) - A ExternalImage object
        
        obj = obj@types.core.BaseImage(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'image_format',[]);
        addParameter(p, 'image_mode',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.image_format = p.Results.image_format;
        obj.image_mode = p.Results.image_mode;
        if strcmp(class(obj), 'types.core.ExternalImage')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.image_format(obj, val)
        obj.image_format = obj.validate_image_format(val);
    end
    function set.image_mode(obj, val)
        obj.image_mode = obj.validate_image_mode(val);
    end
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'char', val);
    end
    function val = validate_image_format(obj, val)
        val = types.util.checkDtype('image_format', 'char', val);
        types.util.validateShape('image_format', {[1]}, val)
    end
    function val = validate_image_mode(obj, val)
        val = types.util.checkDtype('image_mode', 'char', val);
        types.util.validateShape('image_mode', {[1]}, val)
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.BaseImage(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        io.writeAttribute(fid, [fullpath '/image_format'], obj.image_format);
        if ~isempty(obj.image_mode)
            io.writeAttribute(fid, [fullpath '/image_mode'], obj.image_mode);
        end
    end
end

end