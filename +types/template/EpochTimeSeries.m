classdef EpochTimeSeries < types.NWBContainer
    properties %datasets
        count;
        idx_start;
    end
    
    properties %links
        timeseries;
    end
    
    methods
        function obj = EpochTimeSeries(varargin)
            p = inputParser;
            p.addParameter('count', int32([]));
            p.addParameter('idx_start', int32([]));
            p.addParameter('timeseries', []);
            p.addParameter('parent', []);
            p.parse(varargin{:});
            obj.help = 'Data on how an epoch applies to a time series';
            obj.count = p.Results.count;
            obj.idx_start = p.Results.idx_start;
            obj.timeseries = p.Results.timeseries;
            obj.parent = p.Results.parent;
        end
        
        function set.count(obj, val)
            obj.validate_count(val);
            obj.count = val;
        end
        
        function set.idx_start(obj, val)
            obj.validate_idx_start(val);
            obj.idx_start = val;
        end
        
        function set.timeseries(obj, val)
            obj.validate_timeseries(val);
            obj.timeseries = val;
        end
    end
    
    methods(Access=protected)
        function validate_count(~, val)
            validateattributes(val, {'int32'}, {'scalar'});
        end
        
        function validate_idx_start(~, val)
            validateattributes(val, {'int32'}, {'scalar'});
        end
        
        function validate_timeseries(~, val)
            validateattributes(val, {'TimeSeries'}, {'scalar'});
        end
    end
end