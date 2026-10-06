classdef BehavioralEvents < types.core.NWBDataInterface & types.untyped.GroupClass & matnwb.mixin.HasUnnamedGroups
% BEHAVIORALEVENTS - DEPRECATED. Use an `EventsTable` instead, placed in the top-level `/events` group of the `NWBFile`. Each `TimeSeries` formerly stored under `BehavioralEvents` becomes one `EventsTable`. The `timestamps` field maps to the `timestamp` column, and the `data` field maps to an additional column named after the event marker (e.g., `reward_magnitude`, `port_number`); for multi-dimensional `data`, use one column per field. Any other per-event metadata becomes additional columns. Use the `source_description` attribute on the `EventsTable` to record where the events came from (e.g., "Acquisition system", "Thresholding of analog signal ANALOG1 at 3 V", "Manual video review"). Original definition: TimeSeries for storing behavioral events. See description of BehavioralEpochs for more details.
%
% Required Properties:
%  timeseries


% REQUIRED PROPERTIES
properties
    timeseries; % REQUIRED (TimeSeries) TimeSeries object containing behavioral events.
end
properties (Constant, Access = private)
    GroupPropertyNames = ["timeseries"];
end

methods
    function obj = BehavioralEvents(varargin)
        % BEHAVIORALEVENTS - Constructor for BehavioralEvents
        %
        % Syntax:
        %  behavioralEvents = types.core.BEHAVIORALEVENTS() creates a BehavioralEvents object with unset property values.
        %
        %  behavioralEvents = types.core.BEHAVIORALEVENTS(Name, Value) creates a BehavioralEvents object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - timeseries (TimeSeries) - TimeSeries object containing behavioral events.
        %
        % Output Arguments:
        %  - behavioralEvents (types.core.BehavioralEvents) - A BehavioralEvents object
        
        obj = obj@types.core.NWBDataInterface(varargin{:});
        [obj.timeseries, ivarargin] = types.util.parseConstrained(obj,'timeseries', 'types.core.TimeSeries', varargin{:});
        varargin(ivarargin) = [];
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        
        % Only execute validation/setup code when called directly in this class's
        % constructor, not when invoked through superclass constructor chain
        if strcmp(class(obj), 'types.core.BehavioralEvents') %#ok<STISA>
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
            obj.setupHasUnnamedGroupsMixin();
        end
    end
    %% SETTERS
    function set.timeseries(obj, val)
        obj.timeseries = obj.validate_timeseries(val);
    end
    %% VALIDATORS
    
    function val = validate_timeseries(obj, val)
        namedprops = struct();
        constrained = {'types.core.TimeSeries'};
        types.util.checkSet('timeseries', namedprops, constrained, val);
    end
    %% EXPORT
    function refs = export(obj, writer, fullpath, refs)
        refs = export@types.core.NWBDataInterface(obj, writer, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.timeseries.export(writer, fullpath, refs);
    end
end

end