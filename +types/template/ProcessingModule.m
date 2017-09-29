classdef ProcessingModule < types.core.NWBContainer
  properties %attributes
    description;
  end
  
  properties %groups
    groups;
  end
  
  methods
    function obj = ProcessingModule(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('description', {});
      p.addParameter('groups', struct());
      p.parse(varargin{:});
      
      obj = obj@types.core.NWBContainer(varargin{:});
      obj.help = {'A collection of analysis outputs from processing of data'};
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
    function set.description(obj, val)
      obj.validate_description(val);
      obj.description = val;
    end
    
    function set.groups(obj, val)
      obj.validate_groups(val);
      obj.groups = val;
    end
  end
  
  methods(Access=protected) %validate attributes
    function validate_description(~, val)
      if ~iscellstr(val)
        error('ProcessingModule.description:InvalidType Expected cell string array');
      end
    end
    
    function validate_groups(~, val)
      validateattributes(val, {'struct'}, {'scalar'});
      if length(fieldnames(val)) > 1
        error('ProcessingModule.groups:TooFewGroups Expected more groups');
      end
    end
  end
  
  methods %export
    function export(obj, loc_id)
      export@types.NWBContainer(obj, loc_id);
      
      h5util.writeAttribute(loc_id, 'description', obj.description, 'string');
      
      gfn = fieldnames(obj.groups);
      for i=1:length(gfn)
        nm = gfn{i};
        h5util.populateGroup(loc_id, nm, obj.groups.(nm));
      end
    end
  end
end