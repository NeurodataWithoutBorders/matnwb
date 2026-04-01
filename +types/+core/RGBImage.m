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
        %  - data (numeric) - Data property for dataset class (RGBImage)
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
        
        % Only execute validation/setup code when called directly in this class's
        % constructor, not when invoked through superclass constructor chain
        if strcmp(class(obj), 'types.core.RGBImage') %#ok<STISA>
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'numeric', val);
        types.util.validateShape('data', {[3,Inf,Inf]}, val)
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