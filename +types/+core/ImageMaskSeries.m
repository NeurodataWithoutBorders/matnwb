classdef ImageMaskSeries < types.core.ImageSeries & types.untyped.GroupClass
% IMAGEMASKSERIES An alpha mask that is applied to a presented visual stimulus. The 'data' array contains an array of mask values that are applied to the displayed image. Mask values are stored as RGBA. Mask can vary with time. The timestamps array indicates the starting time of a mask, and that mask pattern continues until it's explicitly changed.


% OPTIONAL PROPERTIES
properties
    masked_imageseries; %  ImageSeries
end

methods
    function obj = ImageMaskSeries(varargin)
        % IMAGEMASKSERIES Constructor for ImageMaskSeries
        obj = obj@types.core.ImageSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'masked_imageseries',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.masked_imageseries = p.Results.masked_imageseries;
        if strcmp(class(obj), 'types.core.ImageMaskSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.masked_imageseries(obj, val)
        obj.masked_imageseries = obj.validate_masked_imageseries(val);
    end
    %% VALIDATORS
    
    function val = validate_masked_imageseries(obj, val)
        val = types.util.checkDtype('masked_imageseries', 'types.core.ImageSeries', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.ImageSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.masked_imageseries.export(fid, [fullpath '/masked_imageseries'], refs);
    end
end

end