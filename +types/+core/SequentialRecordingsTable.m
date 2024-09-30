classdef SequentialRecordingsTable < types.hdmf_common.DynamicTable & types.untyped.GroupClass
% SEQUENTIALRECORDINGSTABLE A table for grouping different sequential recordings from the SimultaneousRecordingsTable table together. This is typically used to group together sequential recordings where a sequence of stimuli of the same type with varying parameters have been presented in a sequence.


% REQUIRED PROPERTIES
properties
    simultaneous_recordings; % REQUIRED (DynamicTableRegion) A reference to one or more rows in the SimultaneousRecordingsTable table.
    simultaneous_recordings_index; % REQUIRED (VectorIndex) Index dataset for the simultaneous_recordings column.
    stimulus_type; % REQUIRED (VectorData) The type of stimulus used for the sequential recording.
end

methods
    function obj = SequentialRecordingsTable(varargin)
        % SEQUENTIALRECORDINGSTABLE Constructor for SequentialRecordingsTable
        obj = obj@types.hdmf_common.DynamicTable(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'simultaneous_recordings',[]);
        addParameter(p, 'simultaneous_recordings_index',[]);
        addParameter(p, 'stimulus_type',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.simultaneous_recordings = p.Results.simultaneous_recordings;
        obj.simultaneous_recordings_index = p.Results.simultaneous_recordings_index;
        obj.stimulus_type = p.Results.stimulus_type;
        if strcmp(class(obj), 'types.core.SequentialRecordingsTable')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
        if strcmp(class(obj), 'types.core.SequentialRecordingsTable')
            types.util.dynamictable.checkConfig(obj);
        end
    end
    %% SETTERS
    function set.simultaneous_recordings(obj, val)
        obj.simultaneous_recordings = obj.validate_simultaneous_recordings(val);
    end
    function set.simultaneous_recordings_index(obj, val)
        obj.simultaneous_recordings_index = obj.validate_simultaneous_recordings_index(val);
    end
    function set.stimulus_type(obj, val)
        obj.stimulus_type = obj.validate_stimulus_type(val);
    end
    %% VALIDATORS
    
    function val = validate_simultaneous_recordings(obj, val)
        val = types.util.checkDtype('simultaneous_recordings', 'types.hdmf_common.DynamicTableRegion', val);
    end
    function val = validate_simultaneous_recordings_index(obj, val)
        val = types.util.checkDtype('simultaneous_recordings_index', 'types.hdmf_common.VectorIndex', val);
    end
    function val = validate_stimulus_type(obj, val)
        val = types.util.checkDtype('stimulus_type', 'types.hdmf_common.VectorData', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.DynamicTable(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.simultaneous_recordings.export(fid, [fullpath '/simultaneous_recordings'], refs);
        refs = obj.simultaneous_recordings_index.export(fid, [fullpath '/simultaneous_recordings_index'], refs);
        refs = obj.stimulus_type.export(fid, [fullpath '/stimulus_type'], refs);
    end
end

end