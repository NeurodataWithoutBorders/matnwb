classdef RGBAImage < types.core.Image & types.untyped.DatasetClass
% RGBAIMAGE - A color image with transparency.
%
% Required Properties:
%  data



methods
    function obj = RGBAImage(varargin)
        % RGBAIMAGE - Constructor for RGBAImage
        %
        % Syntax:
        %  rGBAImage = types.core.RGBAIMAGE() creates a RGBAImage object with unset property values.
        %
        %  rGBAImage = types.core.RGBAIMAGE(Name, Value) creates a RGBAImage object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - data (numeric) - No description
        %
        %  - description (char) - Description of the image.
        %
        %  - resolution (single) - Pixel resolution of the image, in pixels per centimeter.
        %
        % Output Arguments:
        %  - rGBAImage (types.core.RGBAImage) - A RGBAImage object
        
        obj = obj@types.core.Image(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'data',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.data = p.Results.data;
        if strcmp(class(obj), 'types.core.RGBAImage')
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