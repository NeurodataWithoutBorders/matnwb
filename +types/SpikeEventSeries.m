classdef SpikeEventSeries < types.ElectricalSeries

  properties
  end

  methods %constructor
    function obj = SpikeEventSeries(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.parse(varargin{:});
      obj = obj@types.ElectricalSeries(varargin{:});
      obj.help = {'Snapshots of spike events from data.'};
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
      export@types.ElectricalSeries(obj, loc_id);
    end
  end
end