classdef TimeIntervals < types.hdmf_common.DynamicTable & types.untyped.GroupClass
% TIMEINTERVALS - A container for aggregating epoch data and the TimeSeries that each epoch applies to.
%
% Required Properties:
%  colnames, description, id, start_time, stop_time


% REQUIRED PROPERTIES
properties
    start_time; % REQUIRED (VectorData) Start time of epoch, in seconds.
    stop_time; % REQUIRED (VectorData) Stop time of epoch, in seconds.
end
% OPTIONAL PROPERTIES
properties
    tags; %  (VectorData) User-defined tags that identify or categorize events.
    tags_index; %  (VectorIndex) Index for tags.
    timeseries; %  (TimeSeriesReferenceVectorData) An index into a TimeSeries object.
    timeseries_index; %  (VectorIndex) Index for timeseries.
end

methods
    function obj = TimeIntervals(varargin)
        % TIMEINTERVALS - Constructor for TimeIntervals
        %
        % Syntax:
        %  timeIntervals = types.core.TIMEINTERVALS() creates a TimeIntervals object with unset property values.
        %
        %  timeIntervals = types.core.TIMEINTERVALS(Name, Value) creates a TimeIntervals object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - colnames (char) - The names of the columns in this table. This should be used to specify an order to the columns.
        %
        %  - description (char) - Description of what is in this dynamic table.
        %
        %  - id (ElementIdentifiers) - Array of unique identifiers for the rows of this dynamic table.
        %
        %  - start_time (VectorData) - Start time of epoch, in seconds.
        %
        %  - stop_time (VectorData) - Stop time of epoch, in seconds.
        %
        %  - tags (VectorData) - User-defined tags that identify or categorize events.
        %
        %  - tags_index (VectorIndex) - Index for tags.
        %
        %  - timeseries (TimeSeriesReferenceVectorData) - An index into a TimeSeries object.
        %
        %  - timeseries_index (VectorIndex) - Index for timeseries.
        %
        %  - vectordata (VectorData) - Vector columns, including index columns, of this dynamic table.
        %
        % Output Arguments:
        %  - timeIntervals (types.core.TimeIntervals) - A TimeIntervals object
        
        obj = obj@types.hdmf_common.DynamicTable(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'start_time',[]);
        addParameter(p, 'stop_time',[]);
        addParameter(p, 'tags',[]);
        addParameter(p, 'tags_index',[]);
        addParameter(p, 'timeseries',[]);
        addParameter(p, 'timeseries_index',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.start_time = p.Results.start_time;
        obj.stop_time = p.Results.stop_time;
        obj.tags = p.Results.tags;
        obj.tags_index = p.Results.tags_index;
        obj.timeseries = p.Results.timeseries;
        obj.timeseries_index = p.Results.timeseries_index;
        if strcmp(class(obj), 'types.core.TimeIntervals')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
        if strcmp(class(obj), 'types.core.TimeIntervals')
            types.util.dynamictable.checkConfig(obj);
        end
    end
    %% SETTERS
    function set.start_time(obj, val)
        obj.start_time = obj.validate_start_time(val);
    end
    function set.stop_time(obj, val)
        obj.stop_time = obj.validate_stop_time(val);
    end
    function set.tags(obj, val)
        obj.tags = obj.validate_tags(val);
    end
    function set.tags_index(obj, val)
        obj.tags_index = obj.validate_tags_index(val);
    end
    function set.timeseries(obj, val)
        obj.timeseries = obj.validate_timeseries(val);
    end
    function set.timeseries_index(obj, val)
        obj.timeseries_index = obj.validate_timeseries_index(val);
    end
    %% VALIDATORS
    
    function val = validate_start_time(obj, val)
        val = types.util.checkDtype('start_time', 'types.hdmf_common.VectorData', val);
    end
    function val = validate_stop_time(obj, val)
        val = types.util.checkDtype('stop_time', 'types.hdmf_common.VectorData', val);
    end
    function val = validate_tags(obj, val)
        val = types.util.checkDtype('tags', 'types.hdmf_common.VectorData', val);
    end
    function val = validate_tags_index(obj, val)
        val = types.util.checkDtype('tags_index', 'types.hdmf_common.VectorIndex', val);
    end
    function val = validate_timeseries(obj, val)
        val = types.util.checkDtype('timeseries', 'types.core.TimeSeriesReferenceVectorData', val);
    end
    function val = validate_timeseries_index(obj, val)
        val = types.util.checkDtype('timeseries_index', 'types.hdmf_common.VectorIndex', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.DynamicTable(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.start_time.export(fid, [fullpath '/start_time'], refs);
        refs = obj.stop_time.export(fid, [fullpath '/stop_time'], refs);
        if ~isempty(obj.tags)
            refs = obj.tags.export(fid, [fullpath '/tags'], refs);
        end
        if ~isempty(obj.tags_index)
            refs = obj.tags_index.export(fid, [fullpath '/tags_index'], refs);
        end
        if ~isempty(obj.timeseries)
            refs = obj.timeseries.export(fid, [fullpath '/timeseries'], refs);
        end
        if ~isempty(obj.timeseries_index)
            refs = obj.timeseries_index.export(fid, [fullpath '/timeseries_index'], refs);
        end
    end
end

end