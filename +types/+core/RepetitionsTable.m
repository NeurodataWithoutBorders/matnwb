classdef RepetitionsTable < types.hdmf_common.DynamicTable & types.untyped.GroupClass
% REPETITIONSTABLE A table for grouping different sequential intracellular recordings together. With each SequentialRecording typically representing a particular type of stimulus, the RepetitionsTable table is typically used to group sets of stimuli applied in sequence.


% REQUIRED PROPERTIES
properties
    sequential_recordings; % REQUIRED (DynamicTableRegion) A reference to one or more rows in the SequentialRecordingsTable table.
    sequential_recordings_index; % REQUIRED (VectorIndex) Index dataset for the sequential_recordings column.
end

methods
    function obj = RepetitionsTable(varargin)
        % REPETITIONSTABLE Constructor for RepetitionsTable
        obj = obj@types.hdmf_common.DynamicTable(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'sequential_recordings',[]);
        addParameter(p, 'sequential_recordings_index',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.sequential_recordings = p.Results.sequential_recordings;
        obj.sequential_recordings_index = p.Results.sequential_recordings_index;
        if strcmp(class(obj), 'types.core.RepetitionsTable')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
        if strcmp(class(obj), 'types.core.RepetitionsTable')
            types.util.dynamictable.checkConfig(obj);
        end
    end
    %% SETTERS
    function set.sequential_recordings(obj, val)
        obj.sequential_recordings = obj.validate_sequential_recordings(val);
    end
    function set.sequential_recordings_index(obj, val)
        obj.sequential_recordings_index = obj.validate_sequential_recordings_index(val);
    end
    %% VALIDATORS
    
    function val = validate_sequential_recordings(obj, val)
        val = types.util.checkDtype('sequential_recordings', 'types.hdmf_common.DynamicTableRegion', val);
    end
    function val = validate_sequential_recordings_index(obj, val)
        val = types.util.checkDtype('sequential_recordings_index', 'types.hdmf_common.VectorIndex', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.DynamicTable(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.sequential_recordings.export(fid, [fullpath '/sequential_recordings'], refs);
        refs = obj.sequential_recordings_index.export(fid, [fullpath '/sequential_recordings_index'], refs);
    end
end

end