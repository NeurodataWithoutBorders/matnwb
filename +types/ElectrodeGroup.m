classdef ElectrodeGroup < types.NWBContainer

  properties
    channel_coordinates;
    channel_description;
    channel_filtering;
    channel_impedance;
    channel_location;
    description;
    device;
    location;
  end

  methods %constructor
    function obj = ElectrodeGroup(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('channel_description', {});
      p.addParameter('channel_location', {});
      p.addParameter('channel_filtering', {});
      p.addParameter('channel_coordinates', {});
      p.addParameter('channel_impedance', {});
      p.addParameter('description', {});
      p.addParameter('location', {});
      p.addParameter('device', []);
      p.parse(varargin{:});
      obj = obj@types.NWBContainer(varargin{:});
      obj.help = {'A physical grouping of channels'};
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
      h5util.writeDataset(loc_id, 'channel_description', obj.channel_description, 'string');
      h5util.writeDataset(loc_id, 'channel_location', obj.channel_location, 'string');
      h5util.writeDataset(loc_id, 'channel_filtering', obj.channel_filtering, 'string');
      h5util.writeDataset(loc_id, 'channel_coordinates', obj.channel_coordinates, 'string');
      h5util.writeDataset(loc_id, 'channel_impedance', obj.channel_impedance, 'string');
      h5util.writeDataset(loc_id, 'description', obj.description, 'string');
      h5util.writeDataset(loc_id, 'location', obj.location, 'string');
      export(obj.device, loc_id, 'device');
    end
  end
end