classdef OpticalSeries < types.ImageSeries

  properties
    distance;
    field_of_view;
    orientation;
  end

  methods %constructor
    function obj = OpticalSeries(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('distance', []);
      p.addParameter('field_of_view', []);
      p.addParameter('orientation', {});
      p.parse(varargin{:});
      obj = obj@types.ImageSeries(varargin{:});
      obj.help = {'Time-series image stack for optical recording or stimulus'};
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
      if ~isempty(obj.distance)
        h5util.writeDataset(loc_id, 'distance', obj.distance, 'single');
      end
      if ~isempty(obj.field_of_view)
        h5util.writeDataset(loc_id, 'field_of_view', obj.field_of_view, 'single');
      end
      if ~isempty(obj.orientation)
        h5util.writeDataset(loc_id, 'orientation', obj.orientation, 'string');
      end
    end
  end
end