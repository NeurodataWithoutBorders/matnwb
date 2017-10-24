classdef Group < handle & matlab.mixin.CustomDisplay %untyped group
  properties
    attributes = util.StructMap;
    datasets = util.StructMap;
    links = util.StructMap;
    groups = util.StructMap;
    classes = util.StructMap;
  end
  
  properties(Constant=true, Access=private)
    TRUEPROPS = {'attributes'; 'datasets'; 'links'; 'groups'; 'classes'};
  end
  
  methods
    function obj = Group(s)
      if nargin > 0 %allow empty Group
        validateattributes(s, {'struct', 'util.StructMap'}, {'scalar'});
        
        for fn=fieldnames(s)'
          nm = fn{1};
          if any(strcmp(nm, obj.TRUEPROPS))
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
          if isempty(pn)
            switch class(r)
              case 'types.untyped.Group'
                s = [substruct('.', 'groups') s];
              case 'types.untyped.Link'
                s = [substruct('.', 'links') s];
              otherwise
                if isnumeric(r)
                  error('Group:subsasgn: please specify whether this numeric value is in ''attributes'' or ''datasets''');
                else
                  s = [substruct('.', 'classes') s];
                end
            end
          else
            s = [substruct('.', pn), s];
          end
          obj = builtin('subsasgn', obj, s, r);
      end
    end
    
    function export(obj, loc_id)
      for pn=obj.TRUEPROPS'
        propnm = pn{1};
        if ~isempty(obj.(propnm))
          for fn=fieldnames(obj.(propnm))'
            nm = fn{1};
            switch propnm
              case 'attributes'
                h5util.writeAttribute(loc_id, nm, obj.attributes.(nm));
              case 'datasets'
                h5util.writeDataset(loc_id, nm, obj.datasets.(nm));
              case 'links'
                export(obj.links.(nm), loc_id, nm);
              case {'groups' 'classes'}
                plist = 'H5P_DEFAULT';
                gid = H5G.create(loc_id, nm, plist, plist, plist);
                export(obj.(propnm).(nm), gid);
                H5G.close(gid);
            end
          end
        end
      end
    end
    
    function names = fieldnames(obj)
      names = properties(obj);
    end
    
    function props = properties(obj)
      props = {};
      for prop=obj.TRUEPROPS'
        pn = prop{1};
        if ~isempty(obj.(pn))
          props = union(props, fieldnames(obj.(pn)));
        end
      end
    end
    
    function propnm = findsubprop(obj, nm)
      propnm = {};
      if ~isprop(obj, nm)
        for prop=obj.TRUEPROPS'
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
      for pnms=obj.TRUEPROPS'
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