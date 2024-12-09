classdef SimultaneousRecordingsTable < types.hdmf_common.DynamicTable & types.untyped.GroupClass
% SIMULTANEOUSRECORDINGSTABLE - A table for grouping different intracellular recordings from the IntracellularRecordingsTable table together that were recorded simultaneously from different electrodes.
%
% Required Properties:
%  id, recordings, recordings_index


% REQUIRED PROPERTIES
properties
    recordings; % REQUIRED (DynamicTableRegion) A reference to one or more rows in the IntracellularRecordingsTable table.
    recordings_index; % REQUIRED (VectorIndex) Index dataset for the recordings column.
end

methods
    function obj = SimultaneousRecordingsTable(varargin)
        % SIMULTANEOUSRECORDINGSTABLE - Constructor for SimultaneousRecordingsTable
        %
        % Syntax:
        %  simultaneousRecordingsTable = types.core.SIMULTANEOUSRECORDINGSTABLE() creates a SimultaneousRecordingsTable object with unset property values.
        %
        %  simultaneousRecordingsTable = types.core.SIMULTANEOUSRECORDINGSTABLE(Name, Value) creates a SimultaneousRecordingsTable object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - colnames (char) - The names of the columns in this table. This should be used to specify an order to the columns.
        %
        %  - description (char) - Description of what is in this dynamic table.
        %
        %  - id (ElementIdentifiers) - Array of unique identifiers for the rows of this dynamic table.
        %
        %  - recordings (DynamicTableRegion) - A reference to one or more rows in the IntracellularRecordingsTable table.
        %
        %  - recordings_index (VectorIndex) - Index dataset for the recordings column.
        %
        %  - vectordata (VectorData) - Vector columns, including index columns, of this dynamic table.
        %
        % Output Arguments:
        %  - simultaneousRecordingsTable (types.core.SimultaneousRecordingsTable) - A SimultaneousRecordingsTable object
        
        obj = obj@types.hdmf_common.DynamicTable(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'recordings',[]);
        addParameter(p, 'recordings_index',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.recordings = p.Results.recordings;
        obj.recordings_index = p.Results.recordings_index;
        if strcmp(class(obj), 'types.core.SimultaneousRecordingsTable')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
        if strcmp(class(obj), 'types.core.SimultaneousRecordingsTable')
            types.util.dynamictable.checkConfig(obj);
        end
    end
    %% SETTERS
    function set.recordings(obj, val)
        obj.recordings = obj.validate_recordings(val);
    end
    function set.recordings_index(obj, val)
        obj.recordings_index = obj.validate_recordings_index(val);
    end
    %% VALIDATORS
    
    function val = validate_recordings(obj, val)
        val = types.util.checkDtype('recordings', 'types.hdmf_common.DynamicTableRegion', val);
    end
    function val = validate_recordings_index(obj, val)
        val = types.util.checkDtype('recordings_index', 'types.hdmf_common.VectorIndex', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.DynamicTable(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.recordings.export(fid, [fullpath '/recordings'], refs);
        refs = obj.recordings_index.export(fid, [fullpath '/recordings_index'], refs);
    end
end

end