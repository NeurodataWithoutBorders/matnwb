classdef MetaClass < dynamicprops
  properties(Hidden=true)
    namespace;
    neurodata_type;
  end
  
  methods
    function obj = MetaClass(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      addParameter(p, 'namespace', {});
      addParameter(p, 'neurodata_type', {});
      parse(p, varargin{:});
      fn = fieldnames(p.Results);
      if ~isempty(fn)
        for fieldcell=fn'
          field = fieldcell{1};
          if ~strcmp(field, 'groups')
            obj.(field) = p.Results.(field);
          end
        end
      end
    end
    
    function export(obj, loc_id)
      h5util.writeAttribute(loc_id, 'namespace', obj.namespace, 'string');
      h5util.writeAttribute(loc_id, 'neurodata_type', obj.neurodata_type, 'string');
    end
  end
end