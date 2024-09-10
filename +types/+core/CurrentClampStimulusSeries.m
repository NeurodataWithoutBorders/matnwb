classdef CurrentClampStimulusSeries < types.core.PatchClampSeries & types.untyped.GroupClass
% CURRENTCLAMPSTIMULUSSERIES Stimulus current applied during current clamp recording.



methods
    function obj = CurrentClampStimulusSeries(varargin)
        % CURRENTCLAMPSTIMULUSSERIES Constructor for CurrentClampStimulusSeries
        varargin = [{'data_unit' 'amperes'} varargin];
        obj = obj@types.core.PatchClampSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'data',[]);
        addParameter(p, 'data_unit',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.data = p.Results.data;
        obj.data_unit = p.Results.data_unit;
        if strcmp(class(obj), 'types.core.CurrentClampStimulusSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    function val = validate_data(obj, val)
    
    end
    function val = validate_data_unit(obj, val)
        if isequal(val, 'amperes')
            val = 'amperes';
        else
            error('Unable to set the ''data_unit'' property of class ''<a href="matlab:doc types.core.CurrentClampStimulusSeries">CurrentClampStimulusSeries</a>'' because it is read-only.')
        end
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.PatchClampSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
    end
end

end