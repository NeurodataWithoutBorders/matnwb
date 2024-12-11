classdef BehavioralEvents < types.core.NWBDataInterface & types.untyped.GroupClass
% BEHAVIORALEVENTS - TimeSeries for storing behavioral events. See description of <a href="#BehavioralEpochs">BehavioralEpochs</a> for more details.
%
% Required Properties:
%  None


% OPTIONAL PROPERTIES
properties
    timeseries; %  (TimeSeries) TimeSeries object containing behavioral events.
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
        if strcmp(class(obj), 'types.core.BehavioralEvents')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
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
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.timeseries)
            refs = obj.timeseries.export(fid, fullpath, refs);
        end
    end
end

end