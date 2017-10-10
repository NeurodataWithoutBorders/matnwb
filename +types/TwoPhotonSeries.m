classdef TwoPhotonSeries < types.ImageSeries

  properties
    field_of_view;
    imaging_plane;
    pmt_gain;
    scan_line_rate;
  end

  methods %constructor
    function obj = TwoPhotonSeries(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('field_of_view', []);
      p.addParameter('pmt_gain', []);
      p.addParameter('scan_line_rate', []);
      p.addParameter('imaging_plane', []);
      p.parse(varargin{:});
      obj = obj@types.ImageSeries(varargin{:});
      obj.help = {'Image stack recorded from 2-photon microscope'};
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
      if ~isempty(obj.field_of_view)
        h5util.writeDataset(loc_id, 'field_of_view', obj.field_of_view, 'single');
      end
      if ~isempty(obj.pmt_gain)
        h5util.writeDataset(loc_id, 'pmt_gain', obj.pmt_gain, 'single');
      end
      if ~isempty(obj.scan_line_rate)
        h5util.writeDataset(loc_id, 'scan_line_rate', obj.scan_line_rate, 'single');
      end
      export(obj.imaging_plane, loc_id, 'imaging_plane');
    end
  end
end