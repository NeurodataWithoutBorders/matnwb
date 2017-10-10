classdef CurrentClampStimulusSeries < types.PatchClampSeries

  properties
  end

  methods %constructor
    function obj = CurrentClampStimulusSeries(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.parse(varargin{:});
      obj = obj@types.PatchClampSeries(varargin{:});
      obj.help = {'Stimulus current applied during current clamp recording'};
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
      export@types.PatchClampSeries(obj, loc_id);
    end
  end
end