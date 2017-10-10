classdef OptogeneticSeries < types.TimeSeries

  properties
    site;
  end

  methods %constructor
    function obj = OptogeneticSeries(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('site', []);
      p.parse(varargin{:});
      obj = obj@types.TimeSeries(varargin{:});
      obj.help = {'Optogenetic stimulus'};
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
      export(obj.site, loc_id, 'site');
    end
  end
end