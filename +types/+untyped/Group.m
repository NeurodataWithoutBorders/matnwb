classdef Group < dynamicprops & matlab.mixin.CustomDisplay %untyped group
  properties
    attributes;
    datasets;
    links;
    groups;
  end
  
  methods
    function obj = Group(s)
      if nargin > 0 %allow empty Group
        validateattributes(s, {'struct', 'util.StructMap'}, {'scalar'});
        
        fn = fieldnames(s);
        for i=1:length(fn)
          nm = fn{i};
          switch(nm)
            case {'attributes' 'datasets' 'links' 'groups'}
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
            [varargout{1:nargout}] = subsref(obj, s(2:end));
          elseif nargout > 1
            varargout{1} = obj;
          end
        case '.'
          mainsub = s(1).subs;
          if isprop(obj, mainsub)
            [varargout{1:nargout}] = builtin('subsref', obj, s);
          else
            for prop={'attributes' 'datasets' 'links' 'groups'}
              if ~isempty(obj.(prop{1})) && isKey(obj.(prop{1}).map, mainsub)
                [varargout{1:nargout}] = subsref(obj, [substruct('.', prop{1}) s]);
                break;
              end
            end
          end
      end
    end
    
    function export(obj, loc_id)
      pn = fieldnames(obj);
      for i=1:length(pn)
        propnm = pn{i};
        fn = fieldnames(obj.(propnm));
        for j=1:length(fn)
          nm = fn{j};
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
          end
        end
      end
    end
  end
  
  methods(Access=protected)
    function groups = getPropertyGroups(obj)
      propnms = fieldnames(obj);
      pgstruct = struct();
      for i=1:length(propnms)
        propnm = propnms{i}; 
        if isempty(obj.(propnm))
          pgstructval = [];
        else
          pgstructval = obj.(propnm).map.keys;
        end
        pgstruct.(propnm) = pgstructval;
      end
      groups = matlab.mixin.util.PropertyGroup(pgstruct);
    end
  end
end