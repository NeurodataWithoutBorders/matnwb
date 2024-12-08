classdef BehavioralTimeSeries < types.core.NWBDataInterface & types.untyped.GroupClass
% BEHAVIORALTIMESERIES - TimeSeries for storing Behavoioral time series data. See description of <a href="#BehavioralEpochs">BehavioralEpochs</a> for more details.
%
% Required Properties:
%  None


% OPTIONAL PROPERTIES
properties
    timeseries; %  (TimeSeries) TimeSeries object containing continuous behavioral data.
end

methods
    function obj = BehavioralTimeSeries(varargin)
        % BEHAVIORALTIMESERIES - Constructor for BehavioralTimeSeries
        %
        % Syntax:
        %  behavioralTimeSeries = types.core.BEHAVIORALTIMESERIES() creates a BehavioralTimeSeries object with unset property values.
        %
        %  behavioralTimeSeries = types.core.BEHAVIORALTIMESERIES(Name, Value) creates a BehavioralTimeSeries object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - timeseries (TimeSeries) - TimeSeries object containing continuous behavioral data.
        %
        % Output Arguments:
        %  - behavioralTimeSeries (types.core.BehavioralTimeSeries) - A BehavioralTimeSeries object
        
        obj = obj@types.core.NWBDataInterface(varargin{:});
        [obj.timeseries, ivarargin] = types.util.parseConstrained(obj,'timeseries', 'types.core.TimeSeries', varargin{:});
        varargin(ivarargin) = [];
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        if strcmp(class(obj), 'types.core.BehavioralTimeSeries')
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