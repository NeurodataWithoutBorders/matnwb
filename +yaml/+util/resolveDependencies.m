%analyze dependencies and determine inherited fields/groups
function s = resolveDependencies(s)
fn = fieldnames(s);
for i=1:length(fn)
  class = s.(fn{i});
  %populate dependency list.  This is will probably be slow.
  deps = {};
  while isfield(class, 'neurodata_type_inc')
    deps{length(deps)+1} = fn{i};
    if isfield(s, class.neurodata_type_inc)
      class = s.(class.neurodata_type_inc);
    else
      s = dbstack();
      error('%s:line %s: Missing type declaration for %s.',...
        s(1).file, s(1).line, class.neurodata_type_inc);
    end
  end
  
  depclass = class;
  
  %traverse backwards through dependencies and determine inherited fields
  for j=length(deps):-1:1
    subclassnm = deps{j};
    subclass = s.(subclassnm);
    propfields = fieldnames(subclass);
    for k=1:length(propfields)
      propnm = propfields{k};
      if isstruct(subclass.(propnm))
        propsubnm = fieldnames(subclass.(propnm));
        if isfield(depclass, propnm)
          for x=1:length(propsubnm)
            nm = propsubnm{x};
            %presumes this is yaml.parse output.  Fails otherwise.
            %e.g. s.TimeSeries.groups.sync.inherited = false|true
            if isfield(depclass, propnm) && isfield(depclass.(propnm), nm)
              s.(subclassnm).(propnm).(nm).inherited = true;
            else
              s.(subclassnm).(propnm).(nm).inherited = false;
            end
          end
        else
          depclass.(propnm) = struct();
          for x=1:length(propsubnm)
            nm = propsubnm{x};
            s.(subclassnm).(propnm).(nm).inherited = false;
          end
        end
        
        %merge into depclass
        propfnm = fieldnames(subclass.(propnm));
        for x=1:length(propfnm)
          nm = propfnm{x};
          depclass.(propnm).(nm) = subclass.(propnm).(nm);
        end
      end
    end
  end
end
end