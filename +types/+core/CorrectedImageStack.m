classdef CorrectedImageStack < types.core.NWBDataInterface & types.untyped.GroupClass
% CORRECTEDIMAGESTACK Reuslts from motion correction of an image stack.


% REQUIRED PROPERTIES
properties
    corrected; % REQUIRED (ImageSeries) Image stack with frames shifted to the common coordinates.
    xy_translation; % REQUIRED (TimeSeries) Stores the x,y delta necessary to align each frame to the common coordinates, for example, to align each frame to a reference image.
end
% OPTIONAL PROPERTIES
properties
    original; %  ImageSeries
end

methods
    function obj = CorrectedImageStack(varargin)
        % CORRECTEDIMAGESTACK Constructor for CorrectedImageStack
        obj = obj@types.core.NWBDataInterface(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'corrected',[]);
        addParameter(p, 'original',[]);
        addParameter(p, 'xy_translation',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.corrected = p.Results.corrected;
        obj.original = p.Results.original;
        obj.xy_translation = p.Results.xy_translation;
        if strcmp(class(obj), 'types.core.CorrectedImageStack')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.corrected(obj, val)
        obj.corrected = obj.validate_corrected(val);
    end
    function set.original(obj, val)
        obj.original = obj.validate_original(val);
    end
    function set.xy_translation(obj, val)
        obj.xy_translation = obj.validate_xy_translation(val);
    end
    %% VALIDATORS
    
    function val = validate_corrected(obj, val)
        val = types.util.checkDtype('corrected', 'types.core.ImageSeries', val);
    end
    function val = validate_original(obj, val)
        val = types.util.checkDtype('original', 'types.core.ImageSeries', val);
    end
    function val = validate_xy_translation(obj, val)
        val = types.util.checkDtype('xy_translation', 'types.core.TimeSeries', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.corrected.export(fid, [fullpath '/corrected'], refs);
        refs = obj.original.export(fid, [fullpath '/original'], refs);
        refs = obj.xy_translation.export(fid, [fullpath '/xy_translation'], refs);
    end
end

end