classdef SpatialSeries < types.TimeSeries

  properties
    reference_frame;
  end

  methods %constructor
    function obj = SpatialSeries(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('reference_frame', {});
      p.parse(varargin{:});
      obj = obj@types.TimeSeries(varargin{:});
      obj.help = {'Stores points in space over time. The data[] array structure is [num samples][num spatial dimensions]'};
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
      if ~isempty(obj.reference_frame)
        h5util.writeDataset(loc_id, 'reference_frame', obj.reference_frame, 'string');
      end
    end
  end
end