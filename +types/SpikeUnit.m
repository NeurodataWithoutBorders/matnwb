classdef SpikeUnit < types.NWBContainer

  properties
    times;
    unit_description;
  end

  methods %constructor
    function obj = SpikeUnit(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('times', []);
      p.addParameter('unit_description', {});
      p.parse(varargin{:});
      obj = obj@types.NWBContainer(varargin{:});
      obj.help = {'Times for a particular UnitTime object'};
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
      h5util.writeDataset(loc_id, 'times', obj.times, 'double');
      h5util.writeDataset(loc_id, 'unit_description', obj.unit_description, 'string');
    end
  end
end