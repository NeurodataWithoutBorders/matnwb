classdef ImageSegmentation < types.core.NWBDataInterface & types.untyped.GroupClass
% IMAGESEGMENTATION - Stores pixels in an image that represent different regions of interest (ROIs) or masks. All segmentation for a given imaging plane is stored together, with storage for multiple imaging planes (masks) supported. Each ROI is stored in its own subgroup, with the ROI group containing both a 2D mask and a list of pixels that make up this mask. Segments can also be used for masking neuropil. If segmentation is allowed to change with time, a new imaging plane (or module) is required and ROI names should remain consistent between them.
%
% Required Properties:
%  planesegmentation


% REQUIRED PROPERTIES
properties
    planesegmentation; % REQUIRED (PlaneSegmentation) Results from image segmentation of a specific imaging plane.
end

methods
    function obj = ImageSegmentation(varargin)
        % IMAGESEGMENTATION - Constructor for ImageSegmentation
        %
        % Syntax:
        %  imageSegmentation = types.core.IMAGESEGMENTATION() creates a ImageSegmentation object with unset property values.
        %
        %  imageSegmentation = types.core.IMAGESEGMENTATION(Name, Value) creates a ImageSegmentation object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - planesegmentation (PlaneSegmentation) - Results from image segmentation of a specific imaging plane.
        %
        % Output Arguments:
        %  - imageSegmentation (types.core.ImageSegmentation) - A ImageSegmentation object
        
        obj = obj@types.core.NWBDataInterface(varargin{:});
        [obj.planesegmentation, ivarargin] = types.util.parseConstrained(obj,'planesegmentation', 'types.core.PlaneSegmentation', varargin{:});
        varargin(ivarargin) = [];
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        if strcmp(class(obj), 'types.core.ImageSegmentation')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.planesegmentation(obj, val)
        obj.planesegmentation = obj.validate_planesegmentation(val);
    end
    %% VALIDATORS
    
    function val = validate_planesegmentation(obj, val)
        namedprops = struct();
        constrained = {'types.core.PlaneSegmentation'};
        types.util.checkSet('planesegmentation', namedprops, constrained, val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.planesegmentation.export(fid, fullpath, refs);
    end
end

end