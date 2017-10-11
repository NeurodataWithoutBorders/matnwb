classdef MeisterImageSeries < types.ImageSeries

  properties
    dx;
    dy;
    pixel_size;
    x;
    y;
  end

  methods %constructor
    function obj = MeisterImageSeries(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('x', []);
      p.addParameter('y', []);
      p.addParameter('dx', []);
      p.addParameter('dy', []);
      p.addParameter('pixel_size', []);
      p.parse(varargin{:});
      obj = obj@types.ImageSeries(varargin{:});
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
      h5util.writeAttribute(loc_id, 'x', obj.x, 'int32');
      h5util.writeAttribute(loc_id, 'y', obj.y, 'int32');
      h5util.writeAttribute(loc_id, 'dx', obj.dx, 'int32');
      h5util.writeAttribute(loc_id, 'dy', obj.dy, 'int32');
      h5util.writeAttribute(loc_id, 'pixel_size', obj.pixel_size, 'double');
    end
  end
end