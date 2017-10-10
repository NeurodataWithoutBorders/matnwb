classdef ImageMaskSeries < types.ImageSeries

  properties
    masked_imageseries;
  end

  methods %constructor
    function obj = ImageMaskSeries(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('masked_imageseries', []);
      p.parse(varargin{:});
      obj = obj@types.ImageSeries(varargin{:});
      obj.help = {'An alpha mask that is applied to a presented visual stimulus'};
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
      export@types.ImageSeries(obj, loc_id);
      export(obj.masked_imageseries, loc_id, 'masked_imageseries');
    end
  end
end