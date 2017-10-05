function writeClass(className, classStruct, dir, namespace)
validateattributes(className, {'char', 'string'}, {'scalartext'});
validateattributes(classStruct, {'struct'}, {'scalar'});
validateattributes(dir, {'char', 'string'}, {'scalartext'});
validateattributes(namespace, {'char', 'string'}, {'scalartext'});

[attr_props, attr_constructs, attr_readonly_constructs] = filterAttributes(classStruct);
[ds_props, ds_constructs, ds_readonly_constructs] = filterDatasets(classStruct);

%filter links
link_props = {};
link_constructs = struct();
if isfield(classStruct, 'links')
  link_props = fieldnames(classStruct.links);
  for i=1:length(link_props)
    link_constructs.(link_props{i}) = '[]';
  end
end

ds_props_flat = ds_props; %ds_props but with formatted property strings
for i=1:length(ds_props_flat)
  nm = ds_props_flat{i};
  if iscell(nm)
    ds_props_flat{i} = [nm{1} '_' nm{2}];
  end
end

if length(union(link_props, union(ds_props_flat, attr_props))) ~=...
    sum([length(link_props) length(ds_props_flat) length(attr_props)])
  error(['writeClass: properties and dataset attributes have conflicting names.', ...
    'Check all property names and <dataset>_<attribute> constructions for conflicting names.']);
end

hasgroups = isfield(classStruct, 'groups');

fid = fopen(fullfile(dir, [className '.m']), 'w+');
fprintf(fid, 'classdef %s', className);
if isfield(classStruct, 'neurodata_type_inc')
  %we assume that the included objects includes 'handle' by default.
  imports = sprintf('%s.%s', namespace, classStruct.neurodata_type_inc);
else
  imports = 'handle'; %root objects should import handle by default.
end
fprintf(fid, [' < %s' newline], imports);

%property definitions
if ~isempty(attr_props)
  fprintf(fid, newline);
  writeProps(fid, attr_props);
end

if ~isempty(ds_props_flat)
  fprintf(fid, newline);
  writeProps(fid, ds_props_flat);
end

if ~isempty(link_props)
  fprintf(fid, newline);
  writeProps(fid, link_props);
end

if isfield(classStruct, 'groups')
  fprintf(fid, newline);
  writeProps(fid, {'groups'});
end

%constructor
fprintf(fid, newline);
fprintf(fid, ['  methods %%constructor' newline]);
fprintf(fid, ['    function obj = %s(varargin)' newline], className);
fprintf(fid, ['      p = inputParser;' newline]);
fprintf(fid, ['      p.KeepUnmatched = true;' newline]);
%write optional params with defaults
writeAddParam(fid, attr_constructs, 'spaces', 6);
writeAddParam(fid, ds_constructs, 'spaces', 6);
writeAddParam(fid, link_constructs, 'spaces', 6);
if hasgroups
  writeAddParam(fid, struct('groups', 'struct()'), 'spaces', 6);
end
fprintf(fid, ['      p.parse(varargin{:});' newline]);
if isfield(classStruct, 'neurodata_type_inc')
  fprintf(fid, ['      obj = obj@%s.%s(varargin{:});' newline],...
    namespace, classStruct.neurodata_type_inc);
end

%set readonly values
writeAddReadonly(fid, attr_readonly_constructs, 'spaces', 6);
writeAddReadonly(fid, ds_readonly_constructs, 'spaces', 6);

%set Results assignment
fprintf(fid, ['      fn = fieldnames(p.Results);' newline]);
fprintf(fid, ['      if ~isempty(fn)' newline]);
fprintf(fid, ['        for i=1:length(fn)' newline]);
fprintf(fid, ['          field = fn{i};' newline]);
fprintf(fid, ['          obj.(field) = p.Results.(field);' newline]);
fprintf(fid, ['        end' newline]);
fprintf(fid, ['      end' newline]);
fprintf(fid, ['    end' newline]);
fprintf(fid, ['  end' newline]);

%setters
fprintf(fid, newline);
fprintf(fid, ['  methods %%setters' newline]);
fprintf(fid, ['  end' newline]);

%validators
fprintf(fid, newline);
fprintf(fid, ['  methods(Access=protected) %%validators' newline]);
fprintf(fid, ['  end' newline]);

%export
fprintf(fid, newline);
fprintf(fid, ['  methods  %%export' newline]);
fprintf(fid, ['    function export(obj, loc_id)' newline]);
if isfield(classStruct, 'neurodata_type_inc')
  fprintf(fid, ['      export@%s.%s(obj, loc_id);' newline],...
    namespace, classStruct.neurodata_type_inc);
end
%write attributes
for i=1:length(attr_props)
  nm = attr_props{i};
  fprintf(fid, ['      h5util.writeAttribute(loc_id, ''%s'', obj.%s, ''%s'');' newline],...
    nm, nm, classStruct.attributes.(nm).dtype);
end
%write datasets
for i=1:length(ds_props)
  nm = ds_props{i};
  
  if ~iscell(nm)
    ds = classStruct.datasets.(nm);
    isopt = isfield(ds, 'quantity') && (strcmp(ds.quantity, '?') || strcmp(ds.quantity, '*'));
    if isopt
      fprintf(fid, ['      if ~isempty(obj.%s)' newline], nm);
      fprintf(fid, '  '); %extra spacing for following block
    end
    if isfield(ds, 'attributes')
      fprintf(fid, ['      id = h5util.writeDataset(loc_id, ''%s'', obj.%s, ''%s'');' newline],...
        nm, nm, ds.dtype);
      dsafn = fieldnames(ds.attributes);
      for j=1:length(dsafn)
        attrnm = dsafn{j};
        if isopt
          fprintf(fid, '  '); %extra spacing for above if block
        end
        fprintf(fid, ['      h5util.writeAttribute(id, ''%s'', obj.%s, ''%s'');' newline],...
          attrnm, [nm '_' attrnm], ds.attributes.(attrnm).dtype);
      end
    else
      fprintf(fid, ['      h5util.writeDataset(loc_id, ''%s'', obj.%s, ''%s'');' newline],...
        nm, nm, ds.dtype);
    end
    if isopt
      fprintf(fid, ['      end' newline]);
    end
  end
end
%write links
for i=1:length(link_props)
  %TODO
end
%write groups
%TODO
fprintf(fid, ['    end' newline]);
fprintf(fid, ['  end' newline]);
fprintf(fid, 'end');
fclose(fid);
end

function [propList, paramStruct, readOnlyStruct] = filterProperties(s, propname, filterFcn)
validateattributes(propname, {'string', 'char'}, {'scalartext'});
validateattributes(s, {'struct'}, {'scalar'});

propList = {};
paramStruct = struct();
readOnlyStruct = struct();

if isfield(s, propname)
  fn = fieldnames(s.(propname));
  for i=1:length(fn)
    [propList, paramStruct, readOnlyStruct] = filterFcn(s, fn{i}, propList, paramStruct, readOnlyStruct);
  end
end
end

function [propList, paramStruct, readOnlyStruct] = filterAttributes(s)
  function [pl, ps, ros] = filter(s, nm, pl, ps, ros)
    attr = s.attributes.(nm);
    if ~attr.inherited
      pl{length(pl)+1} = nm;%attr_props does not include inherited fields.
    end
    
    if isfield(attr, 'value')
      ros.(nm) = dtype2val(attr.dtype, attr.value);
    else
      ps.(nm) = defaultFromStruct(attr);
    end
  end
  [propList, paramStruct, readOnlyStruct] = filterProperties(s, 'attributes', @filter);
end

function [propList, paramStruct, readOnlyStruct] = filterDatasets(s)
%ds_construct creation for non-inherited properties
%side effect: assigns to readonlyStruct and paramStruct
  function [ps, ros] = constructDefaults(nm, prop, ps, ros)
    validateattributes(nm, {'string', 'char'}, {'scalartext'});
    validateattributes(prop, {'struct'}, {'scalar'});
    validateattributes(ps, {'struct'}, {'scalar'});
    validateattributes(ros, {'struct'}, {'scalar'});
    
    if isfield(prop, 'value')
      ros.(nm) = dtype2val(prop.dtype, prop.value);
    else
      ps.(nm) = defaultFromStruct(prop);
    end
  end

  function [pl, ps, ros] = filter(s, nm, pl, ps, ros)
    ds = s.datasets.(nm);
    if ~ds.inherited
      pl{length(pl)+1} = nm;
      [ps, ros] = constructDefaults(nm, s.datasets.(nm), ps, ros);
      if isfield(ds, 'attributes')
        subattr = fieldnames(ds.attributes);
        for j=1:length(subattr)
          %set as two cell arrays
          sanm = subattr{j};
          pl{length(pl)+1} = {nm sanm};
          [ps, ros] = constructDefaults([nm '_' sanm], s.datasets.(nm).attributes.(sanm), ps, ros);
        end
      end
    end
  end
  [propList, paramStruct, readOnlyStruct] = filterProperties(s, 'datasets', @filter);
end

function writeProps(fid, names)
fprintf(fid, ['  properties' newline]);
for i=1:length(names)
  fprintf(fid, ['    %s;' newline], names{i});
end
fprintf(fid, ['  end' newline]);
end

function writeDefStruct(fid, def_struct, svalue, varargin)
validateattributes(fid, {'double'}, {'scalar'});
validateattributes(def_struct, {'struct'}, {'scalar'});
validateattributes(svalue, {'string', 'char'}, {'scalartext'});
p = inputParser;
p.addParameter('spaces', 0, @(x)validateattributes(x, {'numeric'}, {'scalar'}));
p.parse(varargin{:});

names = fieldnames(def_struct);
if ~isempty(names)
  for i=1:length(names)
    nm = names{i};
    for j=1:p.Results.spaces
      fprintf(fid, ' ');
    end
    fprintf(fid, [svalue newline], nm, def_struct.(nm));
  end
end
end

function writeAddParam(fid, def_struct, varargin)
writeDefStruct(fid, def_struct, 'p.addParameter(''%s'', %s);', varargin{:});
end

function writeAddReadonly(fid, def_struct, varargin)
writeDefStruct(fid, def_struct, 'obj.%s = %s;', varargin{:});
end

function val = defaultFromStruct(s)
if isfield(s, 'default_value')
  val = dtype2val(s.dtype, s.default_value);
elseif strcmp(s.dtype, 'string')
  val = '{}';
else
  val = '[]';
end
end

function val = dtype2val(type, val)
switch(type)
  case 'string'
    val = ['{''' val '''}'];
  case 'double'
  otherwise
    val = [type '(' val ')'];
end
end