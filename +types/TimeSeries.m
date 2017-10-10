classdef TimeSeries < types.NWBContainer

  properties
    comments;
    control;
    control_description;
    data;
    data_conversion;
    data_resolution;
    data_unit;
    description;
    starting_time;
    starting_time_rate;
    starting_time_unit;
    timestamps;
    timestamps_interval;
    timestamps_unit;
  end

  methods %constructor
    function obj = TimeSeries(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('comments', {'no comments'});
      p.addParameter('description', {'no description'});
      p.addParameter('source', {});
      p.addParameter('control', []);
      p.addParameter('control_description', {});
      p.addParameter('data', []);
      p.addParameter('data_conversion', 1.0);
      p.addParameter('data_resolution', 0.0);
      p.addParameter('data_unit', {});
      p.addParameter('starting_time', []);
      p.addParameter('starting_time_rate', []);
      p.addParameter('timestamps', []);
      p.addParameter('groups', struct());
      p.parse(varargin{:});
      obj = obj@types.NWBContainer(varargin{:});
      obj.help = {'General time series object'};
      obj.starting_time_unit = {'Seconds'};
      obj.timestamps_interval = int32(1);
      obj.timestamps_unit = {'Seconds'};
      fn = fieldnames(p.Results);
      if ~isempty(fn)
        for i=1:length(fn)
          field = fn{i};
          if ~strcmp(field, 'groups')
            obj.(field) = p.Results.(field);
          end
        end
      end
      gn = fieldnames(p.Results.groups);
      if ~isempty(gn)
        for i=1:length(gn)
          gnm = gn{i};
          if isfield(obj, gnm)
            error('Naming conflict found in TimeSeries object property name: ''%s''', gnm);
          else
            addprop(obj, gnm);
            obj.(gnm) = p.Results.groups.(gnm);
          end
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
      h5util.writeAttribute(loc_id, 'comments', obj.comments, 'string');
      h5util.writeAttribute(loc_id, 'description', obj.description, 'string');
      if ~isempty(obj.control)
        h5util.writeDataset(loc_id, 'control', obj.control, 'uint8');
      end
      if ~isempty(obj.control_description)
        h5util.writeDataset(loc_id, 'control_description', obj.control_description, 'string');
      end
      id = h5util.writeDataset(loc_id, 'data', obj.data, 'any');
      h5util.writeAttribute(id, 'conversion', obj.data_conversion, 'double');
      h5util.writeAttribute(id, 'resolution', obj.data_resolution, 'double');
      h5util.writeAttribute(id, 'unit', obj.data_unit, 'string');
      H5D.close(id);
      if ~isempty(obj.starting_time)
        id = h5util.writeDataset(loc_id, 'starting_time', obj.starting_time, 'double');
        h5util.writeAttribute(id, 'rate', obj.starting_time_rate, 'double');
        h5util.writeAttribute(id, 'unit', obj.starting_time_unit, 'string');
        H5D.close(id);
      end
      id = h5util.writeDataset(loc_id, 'timestamps', obj.timestamps, 'double');
      h5util.writeAttribute(id, 'interval', obj.timestamps_interval, 'int32');
      h5util.writeAttribute(id, 'unit', obj.timestamps_unit, 'string');
      H5D.close(id);
      plist = 'H5P_DEFAULT';
      fnms = fieldnames(obj);
      for i=1:length(fnms)
        fnm = fnms{i};
        if isa(fnm, 'Group')
          gid = H5G.create(loc_id, fnm, plist, plist, plist);
          export(obj.(fnm), gid);
          H5G.close(gid);
        end
      end
    end
  end
end