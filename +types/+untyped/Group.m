classdef Group < dynamicprops & matlab.mixin.CustomDisplay %untyped group
  properties
    attributes;
    datasets;
    links;
    groups;
    classes;
  end
  
  methods
    function obj = Group(s)
      if nargin > 0 %allow empty Group
        validateattributes(s, {'struct', 'util.StructMap'}, {'scalar'});
        
        for fn=fieldnames(s)'
          nm = fn{1};
          if any(strcmp(nm, properties(obj)))
            obj.(nm) = s.(nm);
          end
        end
      end
    end
    
    function varargout = subsref(obj, s)
      switch(s(1).type)
        case '{}'
          error('types.untyped.Group: Unsupported subsref type ''{}''');
        case '()'
          if length(s) > 1
            s = s(2:end);
          elseif nargout > 1
            varargout{1} = obj;
            return;
          end
        case '.'
          mainsub = s(1).subs;
          pn = findsubprop(obj, mainsub);
          if ~isempty(pn)
            s = [substruct('.', pn), s];
          end
      end
      [varargout{1:nargout}] = builtin('subsref', obj, s);
    end
    
    function obj = subsasgn(obj, s, r)
      switch(s(1).type)
        case '{}'
          error('types.untyped.Group: Unsupported subsasgn type ''{}''');
        case '()'
        case '.'
          pn = findsubprop(obj, s(1).subs);
          if ~isempty(pn)
            s = [substruct('.', pn), s];
          end
          obj = builtin('subsasgn', obj, s, r);
      end
    end
    
    function export(obj, loc_id)
      for pn=fieldnames(obj)'
        propnm = pn{1};
        for fn=fieldnames(obj.(propnm))'
          nm = fn{1};
          switch propnm
            case 'attributes'
              h5util.writeAttribute(loc_id, nm, obj.attributes.(nm));
            case 'datasets'
              h5util.writeDataset(loc_id, nm, obj.datasets.(nm));
            case 'links'
              export(obj.links.(nm), loc_id, nm);
            case 'groups'
              plist = 'H5P_DEFAULT';
              gid = H5G.create(loc_id, propnm, plist, plist, plist);
              export(obj.groups.(propnm), gid);
              H5G.close(gid);
            case 'classes'
              export(obj.classes.(propnm), gid);
          end
        end
      end
    end
    
    function names = fieldnames(obj)
      names = {};
      for prop=properties(obj)'
        pn = prop{1};
        if ~isempty(obj.(pn))
          names = union(names, fieldnames(obj.(pn)));
        end
      end
    end
    
    function propnm = findsubprop(obj, nm)
      propnm = {};
      if ~isprop(obj, nm)
        for prop=properties(obj)'
          pn = prop{1};
          if ~isempty(obj.(pn)) && isKey(obj.(pn).map, nm)
            propnm = pn;
            break;
          end
        end
      end
    end
  end
  
  methods(Access=protected)
    function groups = getPropertyGroups(obj)
      fs = struct();
      for pnms=properties(obj)'
        pnm=pnms{1};
        if isempty(obj.(pnm))
          fs.(pnm) = {};
        else
          fs.(pnm) = fieldnames(obj.(pnm))';
        end
      end
      groups = matlab.mixin.util.PropertyGroup(fs);
    end
  end
end