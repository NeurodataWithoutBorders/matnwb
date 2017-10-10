classdef OpticalChannel < types.NWBContainer

  properties
    description;
    emission_lambda;
  end

  methods %constructor
    function obj = OpticalChannel(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('description', {});
      p.addParameter('emission_lambda', {});
      p.parse(varargin{:});
      obj = obj@types.NWBContainer(varargin{:});
      obj.help = {'Metadata about an optical channel used to record from an imaging plane'};
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
      h5util.writeDataset(loc_id, 'emission_lambda', obj.emission_lambda, 'string');
    end
  end
end