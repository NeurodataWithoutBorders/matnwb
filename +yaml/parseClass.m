% Creates a struct of objects that need to be defined
function classes = parseClass(filename)
  function s = verify(s)
    if isfield(s, 'neurodata_type_def')
      if isfield(s, 'groups')
        [s.groups, cstruct] = processGroups(s.groups);
        classes = util.structUniqUnion(classes, cstruct);
      end
      
      if isfield(s, 'attributes')
        s.attributes = processAttributes(s.attributes);
      end
      
      if isfield(s, 'datasets')
        [s.datasets, cstruct] = processDatasets(s.datasets);
        classes = util.structUniqUnion(classes, cstruct);
      end
      
      if isfield(s, 'links')
        s.links = processLinks(s.links);
      end
    else
      error('yaml.read:InvalidSchema Highest group definition must contain a ''neurodata_type_def'' field.');
    end
  end
javaaddpath(fullfile('jar', 'schema.jar'));
classes = struct();

schema = Schema; %prevent screwy behavior when 'clear java' is called
% processList by default searches for a 'name' field but we don't care about
% that.  So we're re-searching the structure for neurodata_type_def here.
anonclasses = processList(schema.read(filename).get('groups'), @verify);
anonfn = fieldnames(anonclasses);
for i=1:length(anonfn)
  s = anonclasses.(anonfn{i});
  typedefnm = s.neurodata_type_def;
  s = rmfield(s, 'neurodata_type_def');
  classes.(typedefnm) = s;
end
end

function anonName = genAnon()
persistent anonindex;
if isempty(anonindex)
  anonindex = 0;
end

anonName = ['Anon_' num2str(anonindex)];
anonindex = anonindex + 1;
end

%general list processor and basic common filter.
function ostruct = processList(l, pfunct)
ostruct = struct();

s_cell = cell(l.toArray());
for i=1:length(s_cell)
  s = yaml.util.hashmap2struct(s_cell{i});
  
  if isfield(s, 'doc')
    s = rmfield(s, 'doc');
  end
  
  s = pfunct(s); %extended functions
  
  if isfield(s, 'name')
    sname = s.name;
  else
    sname = genAnon();
  end
  
  if isfield(ostruct, sname)
    error('processList:DuplicateNames Cannot define attributes of the same name (%s) in the same section.', sname);
  end
  
  if isfield(s, 'name')
    s = rmfield(s, 'name');
  end
  ostruct.(sname) = s;
end
end

function astruct = processAttributes(alist)
  function s = verify(s)
    if ~isfield(s, 'name')
      error('processAttributes:NameRequired Attribute name required.');
    end
    
    if isfield(s, 'dtype')
      s.dtype = yaml.util.schema2matlabTypes(s.dtype);
    end
  end
astruct = processList(alist, @verify);
end

function [dstruct, cstruct] = processDatasets(dlist)
  function s = verify(s)
    if ~isfield(s, 'neurodata_type_def') && ~isfield(s, 'name')
      error('processDatasets:NameRequired Dataset name required.');
    end
    
    %process dims and shape into something readable
    if isfield(s, 'attributes')
      s.attributes = processAttributes(s.attributes);
    end
    
    if isfield(s, 'dims')
      s.dims = cell(s.dims.toArray());
    end
    
    if isfield(s, 'shape')
      s.shape = cell(s.shape.toArray());
    end
    
    if isfield(s, 'dtype')
      s.dtype = yaml.util.schema2matlabTypes(s.dtype);
    end
    
    if isfield(s, 'neurodata_type_def')
      typedefnm = s.neurodata_type_def;
      s_filtered = rmfield(s, 'neurodata_type_def');
      if isfield(s, 'quantity')
        s_filtered = rmfield(s_filtered, 'quantity');
      end
      cstruct.(typedefnm) = s_filtered;
      
      constraint = struct('type', s.neurodata_type_def);
      if isfield(s, 'quantity')
        constraint.quantity = s.quantity;
      end
      s = constraint;
    end
  end
cstruct = struct();
dstruct = processList(dlist, @verify);
end

function ls = processLinks(ll)
  function s = verify(s)
  end
ls = processList(ll, @verify);
end

function [gstruct, cstruct] = processGroups(glist)
  function s = verify(s)
    if isfield(s, 'groups')
      [s.groups, cs] = processGroups(s.groups);
      cstruct = util.structUniqUnion(cstruct, cs);
    end
    
    if isfield(s, 'attributes')
      s.attributes = processAttributes(s.attributes);
    end
    
    if isfield(s, 'datasets')
      [s.datasets, cs] = processDatasets(s.datasets);
      cstruct = util.structUniqUnion(cstruct, cs);
    end
    
    if isfield(s, 'links')
      s.links = processLinks(s.links);
    end
    
    if isfield(s, 'neurodata_type_def')
      typedefnm = s.neurodata_type_def;
      s_filtered = rmfield(s, 'neurodata_type_def');
      if isfield(s, 'quantity')
        s_filtered = rmfield(s_filtered, 'quantity');
      end
      cstruct.(typedefnm) = s_filtered;
      
      groupconstraint = struct('type', s.neurodata_type_def);
      if isfield(s, 'quantity')
        groupconstraint.quantity = s.quantity;
      end
      s = groupconstraint;
    end
  end
cstruct = struct();
gstruct = processList(glist, @verify);
end