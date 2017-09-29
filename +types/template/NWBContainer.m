classdef NWBContainer < dynamicprops
  properties
    source;
    help;
  end
  
  methods
    function obj = NWBContainer(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('help', {});
      p.addParameter('source', {});
      p.parse(varargin{:});
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
    function set.help(obj, val)
      obj.validate_help(val);
      obj.help = val;
    end
    
    function set.source(obj, val)
      obj.validate_source(val);
      obj.source = val;
    end
  end
  
  methods(Access=protected) %validators
    function validate_help(~, val)
      if ~iscellstr(val)
        error('NWBContainer.help:InvalidType Expected cell string array');
      end
    end
    
    function validate_source(~, val)
      if ~iscellstr(val)
        error('NWBContainer.source:InvalidType Expected cell string array');
      end
    end
  end
  
  methods %export
    function export(obj, loc_id)
      h5util.writeAttribute(loc_id, 'help', obj.help, 'string');
      h5util.writeAttribute(loc_id, 'source', obj.source, 'string');
    end
  end
end