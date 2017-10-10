classdef IntervalSeries < types.TimeSeries

  properties
  end

  methods %constructor
    function obj = IntervalSeries(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.parse(varargin{:});
      obj = obj@types.TimeSeries(varargin{:});
      obj.help = {'Stores the start and stop times for events'};
      fn = fieldnames(p.Results);
      if ~isempty(fn)
        for i=1:length(fn)
          field = fn{i};
          obj.(field) = p.Results.(field);
        end
      end
    end
  end

  methods %setters
  end

  methods(Access=protected) %validators
  end

  methods  %export
    function export(obj, loc_id)
      export@types.TimeSeries(obj, loc_id);
    end
  end
end