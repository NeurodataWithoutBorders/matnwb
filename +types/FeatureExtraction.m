classdef FeatureExtraction < types.NWBContainer

  properties
    description;
    electrode_group;
    features;
    times;
  end

  methods %constructor
    function obj = FeatureExtraction(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('description', {});
      p.addParameter('features', []);
      p.addParameter('times', []);
      p.addParameter('electrode_group', []);
      p.parse(varargin{:});
      obj = obj@types.NWBContainer(varargin{:});
      obj.help = {'Container for salient features of detected events'};
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
      h5util.writeDataset(loc_id, 'description', obj.description, 'string');
      h5util.writeDataset(loc_id, 'features', obj.features, 'single');
      h5util.writeDataset(loc_id, 'times', obj.times, 'double');
      export(obj.electrode_group, loc_id, 'electrode_group');
    end
  end
end