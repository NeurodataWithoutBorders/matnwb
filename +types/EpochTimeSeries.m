classdef EpochTimeSeries < types.NWBContainer

  properties
    count;
    idx_start;
    timeseries;
  end

  methods %constructor
    function obj = EpochTimeSeries(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('count', []);
      p.addParameter('idx_start', []);
      p.addParameter('timeseries', []);
      p.parse(varargin{:});
      obj = obj@types.NWBContainer(varargin{:});
      obj.help = {'Data on how an epoch applies to a time series'};
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
      export@types.NWBContainer(obj, loc_id);
      h5util.writeDataset(loc_id, 'count', obj.count, 'int32');
      h5util.writeDataset(loc_id, 'idx_start', obj.idx_start, 'int32');
      export(obj.timeseries, loc_id, 'timeseries');
    end
  end
end