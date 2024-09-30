classdef IntracellularRecordingsTable < types.hdmf_common.AlignedDynamicTable & types.untyped.GroupClass
% INTRACELLULARRECORDINGSTABLE A table to group together a stimulus and response from a single electrode and a single simultaneous recording. Each row in the table represents a single recording consisting typically of a stimulus and a corresponding response. In some cases, however, only a stimulus or a response is recorded as part of an experiment. In this case, both the stimulus and response will point to the same TimeSeries while the idx_start and count of the invalid column will be set to -1, thus, indicating that no values have been recorded for the stimulus or response, respectively. Note, a recording MUST contain at least a stimulus or a response. Typically the stimulus and response are PatchClampSeries. However, the use of AD/DA channels that are not associated to an electrode is also common in intracellular electrophysiology, in which case other TimeSeries may be used.


% REQUIRED PROPERTIES
properties
    electrodes; % REQUIRED (IntracellularElectrodesTable) Table for storing intracellular electrode related metadata.
    responses; % REQUIRED (IntracellularResponsesTable) Table for storing intracellular response related metadata.
    stimuli; % REQUIRED (IntracellularStimuliTable) Table for storing intracellular stimulus related metadata.
end

methods
    function obj = IntracellularRecordingsTable(varargin)
        % INTRACELLULARRECORDINGSTABLE Constructor for IntracellularRecordingsTable
        varargin = [{'description' 'A table to group together a stimulus and response from a single electrode and a single simultaneous recording and for storing metadata about the intracellular recording.'} varargin];
        obj = obj@types.hdmf_common.AlignedDynamicTable(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'description',[]);
        addParameter(p, 'electrodes',[]);
        addParameter(p, 'responses',[]);
        addParameter(p, 'stimuli',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.description = p.Results.description;
        obj.electrodes = p.Results.electrodes;
        obj.responses = p.Results.responses;
        obj.stimuli = p.Results.stimuli;
        if strcmp(class(obj), 'types.core.IntracellularRecordingsTable')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
        if strcmp(class(obj), 'types.core.IntracellularRecordingsTable')
            types.util.dynamictable.checkConfig(obj);
        end
    end
    %% SETTERS
    function set.electrodes(obj, val)
        obj.electrodes = obj.validate_electrodes(val);
    end
    function set.responses(obj, val)
        obj.responses = obj.validate_responses(val);
    end
    function set.stimuli(obj, val)
        obj.stimuli = obj.validate_stimuli(val);
    end
    %% VALIDATORS
    
    function val = validate_description(obj, val)
        if isequal(val, 'A table to group together a stimulus and response from a single electrode and a single simultaneous recording and for storing metadata about the intracellular recording.')
            val = 'A table to group together a stimulus and response from a single electrode and a single simultaneous recording and for storing metadata about the intracellular recording.';
        else
            error('Unable to set the ''description'' property of class ''<a href="matlab:doc types.core.IntracellularRecordingsTable">IntracellularRecordingsTable</a>'' because it is read-only.')
        end
    end
    function val = validate_electrodes(obj, val)
        val = types.util.checkDtype('electrodes', 'types.core.IntracellularElectrodesTable', val);
    end
    function val = validate_responses(obj, val)
        val = types.util.checkDtype('responses', 'types.core.IntracellularResponsesTable', val);
    end
    function val = validate_stimuli(obj, val)
        val = types.util.checkDtype('stimuli', 'types.core.IntracellularStimuliTable', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.AlignedDynamicTable(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.electrodes.export(fid, [fullpath '/electrodes'], refs);
        refs = obj.responses.export(fid, [fullpath '/responses'], refs);
        refs = obj.stimuli.export(fid, [fullpath '/stimuli'], refs);
    end
end

end