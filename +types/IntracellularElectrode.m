classdef IntracellularElectrode < types.NWBContainer

  properties
    description;
    device;
    filtering;
    initial_access_resistance;
    location;
    resistance;
    seal;
    slice;
  end

  methods %constructor
    function obj = IntracellularElectrode(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('description', {});
      p.addParameter('device', {});
      p.addParameter('filtering', {});
      p.addParameter('initial_access_resistance', {});
      p.addParameter('location', {});
      p.addParameter('resistance', {});
      p.addParameter('seal', {});
      p.addParameter('slice', {});
      p.parse(varargin{:});
      obj = obj@types.NWBContainer(varargin{:});
      obj.help = {'Metadata about an intracellular electrode'};
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
      if ~isempty(obj.device)
        h5util.writeDataset(loc_id, 'device', obj.device, 'string');
      end
      if ~isempty(obj.filtering)
        h5util.writeDataset(loc_id, 'filtering', obj.filtering, 'string');
      end
      if ~isempty(obj.initial_access_resistance)
        h5util.writeDataset(loc_id, 'initial_access_resistance', obj.initial_access_resistance, 'string');
      end
      if ~isempty(obj.location)
        h5util.writeDataset(loc_id, 'location', obj.location, 'string');
      end
      if ~isempty(obj.resistance)
        h5util.writeDataset(loc_id, 'resistance', obj.resistance, 'string');
      end
      if ~isempty(obj.seal)
        h5util.writeDataset(loc_id, 'seal', obj.seal, 'string');
      end
      if ~isempty(obj.slice)
        h5util.writeDataset(loc_id, 'slice', obj.slice, 'string');
      end
    end
  end
end