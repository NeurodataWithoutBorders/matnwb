classdef IndexSeries < types.TimeSeries

  properties
    indexed_timeseries;
  end

  methods %constructor
    function obj = IndexSeries(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('indexed_timeseries', []);
      p.parse(varargin{:});
      obj = obj@types.TimeSeries(varargin{:});
      obj.help = {'A sequence that is generated from an existing image stack. Frames can be presented in an arbitrary order. The data[] field stores frame number in reference stack'};
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
      export(obj.indexed_timeseries, loc_id, 'indexed_timeseries');
    end
  end
end