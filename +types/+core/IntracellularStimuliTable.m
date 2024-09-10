classdef IntracellularStimuliTable < types.hdmf_common.DynamicTable & types.untyped.GroupClass
% INTRACELLULARSTIMULITABLE Table for storing intracellular stimulus related metadata.


% REQUIRED PROPERTIES
properties
    stimulus; % REQUIRED (TimeSeriesReferenceVectorData) Column storing the reference to the recorded stimulus for the recording (rows).
end
% OPTIONAL PROPERTIES
properties
    stimulus_template; %  (TimeSeriesReferenceVectorData) Column storing the reference to the stimulus template for the recording (rows).
end

methods
    function obj = IntracellularStimuliTable(varargin)
        % INTRACELLULARSTIMULITABLE Constructor for IntracellularStimuliTable
        varargin = [{'description' 'Table for storing intracellular stimulus related metadata.'} varargin];
        obj = obj@types.hdmf_common.DynamicTable(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'description',[]);
        addParameter(p, 'stimulus',[]);
        addParameter(p, 'stimulus_template',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.description = p.Results.description;
        obj.stimulus = p.Results.stimulus;
        obj.stimulus_template = p.Results.stimulus_template;
        if strcmp(class(obj), 'types.core.IntracellularStimuliTable')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
        if strcmp(class(obj), 'types.core.IntracellularStimuliTable')
            types.util.dynamictable.checkConfig(obj);
        end
    end
    %% SETTERS
    function set.stimulus(obj, val)
        obj.stimulus = obj.validate_stimulus(val);
    end
    function set.stimulus_template(obj, val)
        obj.stimulus_template = obj.validate_stimulus_template(val);
    end
    %% VALIDATORS
    
    function val = validate_description(obj, val)
        if isequal(val, 'Table for storing intracellular stimulus related metadata.')
            val = 'Table for storing intracellular stimulus related metadata.';
        else
            error('Unable to set the ''description'' property of class ''<a href="matlab:doc types.core.IntracellularStimuliTable">IntracellularStimuliTable</a>'' because it is read-only.')
        end
    end
    function val = validate_stimulus(obj, val)
        val = types.util.checkDtype('stimulus', 'types.core.TimeSeriesReferenceVectorData', val);
    end
    function val = validate_stimulus_template(obj, val)
        val = types.util.checkDtype('stimulus_template', 'types.core.TimeSeriesReferenceVectorData', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.DynamicTable(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.stimulus.export(fid, [fullpath '/stimulus'], refs);
        if ~isempty(obj.stimulus_template)
            refs = obj.stimulus_template.export(fid, [fullpath '/stimulus_template'], refs);
        end
    end
end

end