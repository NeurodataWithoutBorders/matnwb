classdef OptogeneticStimulusSite < types.NWBContainer

  properties
    description;
    device;
    excitation_lambda;
    location;
  end

  methods %constructor
    function obj = OptogeneticStimulusSite(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('description', {});
      p.addParameter('device', {});
      p.addParameter('excitation_lambda', {});
      p.addParameter('location', {});
      p.parse(varargin{:});
      obj = obj@types.NWBContainer(varargin{:});
      obj.help = {'Metadata about an optogenetic stimulus site'};
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
      h5util.writeDataset(loc_id, 'device', obj.device, 'string');
      h5util.writeDataset(loc_id, 'excitation_lambda', obj.excitation_lambda, 'string');
      h5util.writeDataset(loc_id, 'location', obj.location, 'string');
    end
  end
end