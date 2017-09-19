classdef TimeSeries < types.core.NWBContainer
  properties %attributes
    comments;
    description;
    source;
  end
  
  properties %datasets + dataset attributes
    data;
    data_conversion;
    data_resolution;
    data_unit;
    timestamps;
    timestamps_interval;
    timestamps_unit;
  end
  
  properties %optional datasets
    control;
    control_description;
    sync;
    starting_time;
    starting_time_rate;
    starting_time_unit;
  end
  
  methods %constructor
    function obj = TimeSeries(varargin)
      p = inputParser;
      p.addParameter('comments', {'no comments'});
      p.addParameter('description', {'no description'});
      p.addParameter('source', {});
      p.addParameter('data', []);
      p.addParameter('data_conversion', 1);
      p.addParameter('data_resolution', 0);
      p.addParameter('data_unit', {});
      p.addParameter('timestamps', []);
      p.addParameter('timestamps_interval', int32(1));
      p.addParameter('timestamps_unit', {'Seconds'});
      p.addParameter('control', uint8([]));
      p.addParameter('control_description', {});
      p.addParameter('sync', struct());
      p.addParameter('starting_time', []);
      p.addParameter('starting_time_rate', []);
      p.addParameter('starting_time_unit', {'Seconds'});
      p.parse(varargin{:});
      
      obj = obj@types.core.NWBContainer(varargin{:});
      obj.help = ['Name of TimeSeries or Modules that serve as the source '...
        'for the data contained here.  It can also be the '...
        'name of a device, for stimulus or acquisition data'];
      fn = fieldnames(p.Results);
      if ~isempty(fn)
        for i=1:length(fn)
          field = fn{i};
          obj.(field) = p.Results.(field);
        end
      end
    end
  end
  
  methods %set attributes
    function set.comments(obj, val)
      obj.validate_comments(val);
      obj.comments = val;
    end
    
    function set.description(obj, val)
      obj.validate_description(val);
      obj.description = val;
    end
    
    function set.source(obj, val)
      obj.validate_source(val);
      obj.source = val;
    end
    
    function set.data(obj, val)
      obj.validate_data(val);
      obj.data = val;
    end
    
    function set.data_conversion(obj, val)
      obj.validate_data_conversion(val);
      obj.data_conversion = val;
    end
    
    function set.data_resolution(obj, val)
      obj.validate_data_resolution(val);
      obj.data_resolution = val;
    end
    
    function set.data_unit(obj, val)
      obj.validate_data_unit(val);
      obj.data_unit = val;
    end
    
    function set.timestamps(obj, val)
      obj.validate_timestamps(val);
      obj.timestamps = val;
    end
    
    function set.timestamps_interval(obj, val)
      obj.validate_timestamps_interval(val);
      obj.timestamps_interval = val;
    end
    
    function set.timestamps_unit(obj, val)
      obj.validate_timestamps_unit(val);
      obj.timestamps_unit = val;
    end
    
    function set.control(obj, val)
      obj.validate_control(val);
      obj.control = val;
    end
    
    function set.control_description(obj, val)
      obj.validate_control_description(val);
      obj.control_description = val;
    end
    
    function set.sync(obj, val)
      obj.validate_sync(val);
      obj.sync = val;
    end
    
    function set.starting_time(obj, val)
      obj.validate_starting_time(obj, val);
      obj.starting_time = val;
    end
    
    function set.starting_time_rate(obj, val)
      obj.validate_starting_time_rate(obj, val);
      obj.starting_time_rate = val;
    end
    
    function set.starting_time_unit(obj, val)
      obj.validate_starting_time_unit(obj, val);
      obj.starting_time_unit = val;
    end
  end
  
  methods(Access=protected) %validators
    function validate_comments(~, val)
      if ~iscellstr(val)
        error('TimeSeries.comments: Expected Cell String Array');
      end
    end
    
    function validate_description(~, val)
      if ~iscellstr(val)
        error('TimeSeries.description: Expected Cell String Array');
      end
    end
    
    function validate_source(~, val)
      if ~iscellstr(val)
        error('TimeSeries.source: Expected Cell String Array');
      end
    end
    
    function validate_data(~, ~)
    end
    
    function validate_data_conversion(~, val)
      validateattributes(val, {'single', 'double'}, {'scalar'});
    end
    
    function validate_data_resolution(~, val)
      validateattributes(val, {'single', 'double'}, {'scalar'});
    end
    
    function validate_data_unit(~, val)
      if ~iscellstr(val)
        error('TimeSeries.data_unit: Expected Cell String Array');
      end
    end
    
    function validate_timestamps(~, val)
      validateattributes(val, {'double'}, {'vector'});
    end
    
    function validate_timestamps_interval(~, val)
      validateattributes(val, {'int32'}, {'scalar'});
    end
    
    function validate_timestamps_unit(~, val)
      if ~iscellstr(val)
        error('TimeSeries.unit: Expected Cell String Array');
      end
    end
    
    function validate_control(~, val)
      if ~isempty(val)
        validateattributes(val, {'uint8'}, {'vector'})
      end
    end
    
    function validate_control_description(~, val)
      if ~iscellstr(val)
        error('TimeSeries.control_description: Expected Cell String Array');
      end
    end
    
    function validate_sync(~, val)
      validateattributes(val, {'cell'}, {});
    end
    
    function validate_starting_time(~, val)
      if ~isempty(val)
        validateattributes(val, {'double'}, {'scalar'});
      end
    end
    
    function validate_starting_time_rate(obj, val)
      if ~isempty(obj.starting_time)
        validateattributes(val, {'single', 'double'}, {'scalar'});
      end
    end
    
    function validate_starting_time_unit(obj, val)
      if ~isempty(obj.starting_time)
        if ~iscellstr(val)
          error('TimeSeries.starting_time_unit: Expected Cell String Array');
        end
      end
    end
  end
  
  methods %export
    %where loc_id is used by low level HDF5 Library
    %loc_id should be the root group
    function export(obj, loc_id)
      export@types.NWBContainer(obj, loc_id);

      h5util.writeAttribute(loc_id, 'comments', obj.comments, 'string');
      h5util.writeAttribute(loc_id, 'description', obj.description, 'string');
      h5util.writeAttribute(loc_id, 'source', obj.source, 'string');
      
      if ~isempty(obj.control)
        h5util.writeDataset(loc_id, 'control', obj.control);
        h5util.writeDataset(loc_id, 'control_description', obj.control_description, 'string');
      end
      
      id = h5util.writeDataset(loc_id, 'data', obj.data);
      h5util.writeAttribute(id, 'conversion', obj.data_conversion);
      h5util.writeAttribute(id, 'resolution', obj.data_resolution);
      h5util.writeAttribute(id, 'unit', obj.data_unit, 'string');
      H5D.close(id);
      
      id = h5util.writeDataset(loc_id, 'timestamps', obj.timestamps);
      h5util.writeAttribute(id, 'interval', obj.timestamps_interval);
      h5util.writeAttribute(id, 'unit', obj.timestamps_unit, 'string');
      H5D.close(id);
      
      id = h5util.writeDataset(loc_id, 'starting_time', obj.starting_time);
      h5util.writeAttribute(id, 'rate', obj.starting_time_rate);
      h5util.writeAttribute(id, 'unit', obj.starting_time_unit, 'string');
      H5D.close(id);
      
      h5util.populateGroup(loc_id, 'sync', obj.sync);
    end
  end
end
