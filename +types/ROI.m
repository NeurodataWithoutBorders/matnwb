classdef ROI < types.NWBContainer

  properties
    img_mask;
    pix_mask;
    pix_mask_weight;
    roi_description;
  end

  methods %constructor
    function obj = ROI(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('img_mask', []);
      p.addParameter('pix_mask', []);
      p.addParameter('pix_mask_weight', []);
      p.addParameter('roi_description', {});
      p.parse(varargin{:});
      obj = obj@types.NWBContainer(varargin{:});
      obj.help = {'Region of interest, as determined by image segmentation'};
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
      export@types.NWBContainer(obj, loc_id);
      h5util.writeDataset(loc_id, 'img_mask', obj.img_mask, 'single');
      h5util.writeDataset(loc_id, 'pix_mask', obj.pix_mask, 'uint16');
      h5util.writeDataset(loc_id, 'pix_mask_weight', obj.pix_mask_weight, 'single');
      h5util.writeDataset(loc_id, 'roi_description', obj.roi_description, 'string');
    end
  end
end