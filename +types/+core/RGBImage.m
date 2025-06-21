classdef RGBImage < types.core.Image & types.untyped.DatasetClass
% RGBIMAGE - A color image.
%
% Required Properties:
%  data



methods
    function obj = RGBImage(varargin)
        % RGBIMAGE - Constructor for RGBImage
        %
        % Syntax:
        %  rGBImage = types.core.RGBIMAGE() creates a RGBImage object with unset property values.
        %
        %  rGBImage = types.core.RGBIMAGE(Name, Value) creates a RGBImage object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - data (numeric) - No description
        %
        %  - description (char) - Description of the image.
        %
        %  - resolution (single) - Pixel resolution of the image, in pixels per centimeter.
        %
        % Output Arguments:
        %  - rGBImage (types.core.RGBImage) - A RGBImage object
        
        obj = obj@types.core.Image(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        if strcmp(class(obj), 'types.core.RGBImage')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'numeric', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.Image(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
    end
end

end