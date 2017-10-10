classdef ImageSeries < types.TimeSeries

  properties
    bits_per_pixel;
    dimension;
    external_file;
    external_file_starting_frame;
    format;
  end

  methods %constructor
    function obj = ImageSeries(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('bits_per_pixel', []);
      p.addParameter('dimension', []);
      p.addParameter('external_file', {});
      p.addParameter('external_file_starting_frame', []);
      p.addParameter('format', {});
      p.parse(varargin{:});
      obj = obj@types.TimeSeries(varargin{:});
      obj.help = {'Storage object for time-series 2-D image data'};
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
      if ~isempty(obj.bits_per_pixel)
        h5util.writeDataset(loc_id, 'bits_per_pixel', obj.bits_per_pixel, 'int32');
      end
      if ~isempty(obj.dimension)
        h5util.writeDataset(loc_id, 'dimension', obj.dimension, 'int32');
      end
      if ~isempty(obj.external_file)
        id = h5util.writeDataset(loc_id, 'external_file', obj.external_file, 'string');
        h5util.writeAttribute(id, 'starting_frame', obj.external_file_starting_frame, 'int32');
        H5D.close(id);
      end
      if ~isempty(obj.format)
        h5util.writeDataset(loc_id, 'format', obj.format, 'string');
      end
    end
  end
end