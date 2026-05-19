classdef EventsTable < types.hdmf_common.DynamicTable & types.untyped.GroupClass
% EVENTSTABLE - A column-based table to store information about events, one event per row. Use `EventsTable` when each row is anchored at a single timestamp and duration is absent, optional, or mixed across rows. Additional columns may be added to store metadata about each event, such as the duration of the event. Examples include TTL pulses, licks, rewards, stimulus onsets, and detected ripples.
%
% Required Properties:
%  colnames, description, id, timestamp


% REQUIRED PROPERTIES
properties
    timestamp; % REQUIRED (TimestampVectorData) Column containing the time that each event occurred, in seconds, from the session start time.
end
% OPTIONAL PROPERTIES
properties
    annotation; %  (VectorData) Column containing user annotations about events.
    duration; %  (DurationVectorData) Optional column containing the duration of each event, in seconds. A value of NaN can be used for events without a duration or with a duration that is not yet specified.
end

methods
    function obj = EventsTable(varargin)
        % EVENTSTABLE - Constructor for EventsTable
        %
        % Syntax:
        %  eventsTable = types.core.EVENTSTABLE() creates a EventsTable object with unset property values.
        %
        %  eventsTable = types.core.EVENTSTABLE(Name, Value) creates a EventsTable object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - annotation (VectorData) - Column containing user annotations about events.
        %
        %  - colnames (char) - The names of the columns in this table. This should be used to specify an order to the columns.
        %
        %  - description (char) - A description of the events stored in the table, including information about how the event times were computed, especially if the times are the result of processing or filtering raw data. For example, if the experimenter is encoding different types of events using a strobed or N-bit encoding, then the description should describe which channels were used and how the event time is computed, e.g., as the rise time of the first bit.
        %
        %  - duration (DurationVectorData) - Optional column containing the duration of each event, in seconds. A value of NaN can be used for events without a duration or with a duration that is not yet specified.
        %
        %  - id (ElementIdentifiers) - Array of unique identifiers for the rows of this dynamic table.
        %
        %  - meanings_tables (MeaningsTable) - MeaningsTable objects that provide meanings for values in VectorData columns within this DynamicTable. Tables should be named according to the column they provide meanings for with a "_meanings" suffix. e.g., if a VectorData column is named "stimulus_type", the corresponding MeaningsTable should be named "stimulus_type_meanings".
        %
        %  - timestamp (TimestampVectorData) - Column containing the time that each event occurred, in seconds, from the session start time.
        %
        %  - vectordata (VectorData) - Vector columns, including index columns, of this dynamic table.
        %
        % Output Arguments:
        %  - eventsTable (types.core.EventsTable) - A EventsTable object
        
        obj = obj@types.hdmf_common.DynamicTable(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'annotation',[]);
        addParameter(p, 'duration',[]);
        addParameter(p, 'timestamp',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.annotation = p.Results.annotation;
        obj.duration = p.Results.duration;
        obj.timestamp = p.Results.timestamp;
        
        % Only execute validation/setup code when called directly in this class's
        % constructor, not when invoked through superclass constructor chain
        if strcmp(class(obj), 'types.core.EventsTable') %#ok<STISA>
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
            types.util.dynamictable.checkConfig(obj);
        end
    end
    %% SETTERS
    function set.annotation(obj, val)
        obj.annotation = obj.validate_annotation(val);
        obj.postset_annotation()
    end
    function postset_annotation(obj)
        types.util.dynamictable.syncNamedColumn(obj, 'annotation');
    end
    function set.duration(obj, val)
        obj.duration = obj.validate_duration(val);
        obj.postset_duration()
    end
    function postset_duration(obj)
        types.util.dynamictable.syncNamedColumn(obj, 'duration');
    end
    function set.timestamp(obj, val)
        obj.timestamp = obj.validate_timestamp(val);
        obj.postset_timestamp()
    end
    function postset_timestamp(obj)
        types.util.dynamictable.syncNamedColumn(obj, 'timestamp');
    end
    %% VALIDATORS
    
    function val = validate_annotation(obj, val)
        types.util.checkType('annotation', 'types.hdmf_common.VectorData', val);
        if ~isempty(val)
            [val, originalVal] = types.util.unwrapValue(val);
            val = types.util.checkDtype('annotation', 'char', val);
            types.util.validateShape('annotation', {[Inf]}, val)
            val = types.util.rewrapValue(val, originalVal);
        end
    end
    function val = validate_description(obj, val)
        val = types.util.checkDtype('description', 'char', val);
        types.util.validateShape('description', {[1]}, val)
    end
    function val = validate_duration(obj, val)
        types.util.checkType('duration', 'types.core.DurationVectorData', val);
    end
    function val = validate_timestamp(obj, val)
        types.util.checkType('timestamp', 'types.core.TimestampVectorData', val);
    end
    %% EXPORT
    function refs = export(obj, writer, fullpath, refs)
        refs = export@types.hdmf_common.DynamicTable(obj, writer, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.annotation)
            refs = obj.annotation.export(writer, [fullpath '/annotation'], refs);
        end
        if ~isempty(obj.duration)
            refs = obj.duration.export(writer, [fullpath '/duration'], refs);
        end
        refs = obj.timestamp.export(writer, [fullpath '/timestamp'], refs);
    end
end

end