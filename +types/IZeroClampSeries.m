classdef IZeroClampSeries < types.CurrentClampSeries

  properties
  end

  methods %constructor
    function obj = IZeroClampSeries(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.parse(varargin{:});
      obj = obj@types.CurrentClampSeries(varargin{:});
      obj.help = {'Voltage from intracellular recordings when all current and amplifier settings are off'};
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
      export@types.CurrentClampSeries(obj, loc_id);
    end
  end
end