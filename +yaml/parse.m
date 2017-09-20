% Creates a struct of objects that need to be defined
function classes = parse(filename)
javaaddpath(fullfile('+yaml', 'jar', 'yaml.jar'));

classes = struct();
%convert hashmap to cell array of type definitions
types = cell(yaml.read(filename).get('groups').toArray());
for i=1:length(types)
  typedef = yaml.util.hashmap2struct(types{i});
  
  if isfield(typedef, 'neurodata_type_def')
    if isfield(typedef, 'doc')
      typedef = rmfield(typedef, 'doc');
    end
    
    if isfield(typedef, 'groups')
      typedef.groups = processGroups(typedef.groups);
    end
    
    if isfield(typedef, 'attributes')
      typedef.attributes = processAttributes(typedef.attributes);
    end
    
    if isfield(typedef, 'datasets')
      typedef.datasets = processDatasets(typedef.datasets);
    end
    
    classname = typedef.neurodata_type_def;
    typedef = rmfield(typedef, 'neurodata_type_def'); %remove redundant name
    classes.(classname) = typedef;
  else
    error('yaml.read:InvalidSchema Highest group definition must contain a ''neurodata_type_def'' field.');
  end
end
end

%general list processor and basic common filter.
function ostruct = processList(l, pfunct)
persistent anonindex;
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
    if isempty(anonindex)
      anonindex = 0;
    end
    sname = ['anon_' num2str(anonindex)];
    anonindex = anonindex + 1;
  end
  
  if isfield(ostruct, sname)
    error('yaml.read.processList:DuplicateNames Cannot define attributes of the same name (%s) in the same section.', sname);
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
      error('yaml.read.processAttributes:NameRequired Attribute name required.');
    end
  end
astruct = processList(alist, @verify);
end

function dstruct = processDatasets(dlist)
  function s = verify(s)
    if ~isfield(s, 'name')
      error('yaml.read.processDatasets:NameRequired Dataset name required.');
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
  end
dstruct = processList(dlist, @verify);
end

function gstruct = processGroups(glist)
  function s = verify(s)
    if isfield(s, 'groups')
      s.groups = processGroups(s.groups);
    end
    
    if isfield(s, 'attributes')
      s.attributes = processAttributes(s.attributes);
    end
    
    if isfield(s, 'datasets')
      s.datasets = processDatasets(s.datasets);
    end
  end
gstruct = processList(glist, @verify);
end