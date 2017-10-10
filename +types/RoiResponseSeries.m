classdef RoiResponseSeries < types.TimeSeries

  properties
    roi_names;
    segmentation_interface;
  end

  methods %constructor
    function obj = RoiResponseSeries(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('roi_names', {});
      p.addParameter('segmentation_interface', []);
      p.parse(varargin{:});
      obj = obj@types.TimeSeries(varargin{:});
      obj.help = {'ROI responses over an imaging plane. Each row in data[] should correspond to the signal from one ROI'};
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
      h5util.writeDataset(loc_id, 'roi_names', obj.roi_names, 'string');
      export(obj.segmentation_interface, loc_id, 'segmentation_interface');
    end
  end
end