classdef Epoch < types.NWBContainer
  properties %datasets
    description;
    start_time;
    stop_time;
    tags;
  end
  
  methods
    function obj = Epoch(varargin)
      p = inputParser;
      p.addParameter('description', '');
      p.addParameter('start_time', []);
      p.addParameter('stop_time', []);
      p.addParameter('tags', string());
      p.parse(varargin{:});
      obj = obj@types.NWBContainer(varargin{:});
      fn = fieldnames(p.Results);
      if ~isempty(fn)
        for i=1:length(fn)
          field = fn{i};
          obj.(field) = p.Results.(field);
        end
      end
      obj.help = 'A general epoch object';
    end
    
    function set.description(obj, val)
      obj.validate_description(val);
      obj.description = val;
    end
    
    function set.start_time(obj, val)
      obj.validate_start_time(val);
      obj.start_time = val;
    end
    
    function set.stop_time(obj, val)
      obj.validate_stop_time(val);
      obj.stop_time = val;
    end
    
    function set.tags(obj, val)
      obj.validate_tags(val);
      obj.tags = val;
    end
  end
  
  methods(Access=protected)
    function validate_description(~, val)
      validateattributes(val, {'string', 'char'}, {'scalartext'});
    end
    
    function validate_start_time(~, val)
      validateattributes(val, {'double'}, {'scalar'});
    end
    
    function validate_stop_time(~, val)
      validateattributes(val, {'double'}, {'scalar'});
    end
    
    function validate_tags(~, val)
      validateattributes(val, {'string', 'cell'}, {'vector'});
      if iscell(val) && ~iscellstr(val)
        error('Epoch tags should be string array or cellstr array');
      end
    end
  end
end