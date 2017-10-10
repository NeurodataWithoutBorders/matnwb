classdef PatchClampSeries < types.TimeSeries

  properties
    electrode;
    gain;
  end

  methods %constructor
    function obj = PatchClampSeries(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('gain', []);
      p.addParameter('electrode', []);
      p.parse(varargin{:});
      obj = obj@types.TimeSeries(varargin{:});
      obj.help = {'Superclass definition for patch-clamp data'};
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
      if ~isempty(obj.gain)
        h5util.writeDataset(loc_id, 'gain', obj.gain, 'double');
      end
      export(obj.electrode, loc_id, 'electrode');
    end
  end
end