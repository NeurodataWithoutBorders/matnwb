function writeClass(className, classStruct, namespace)
validateattributes(className, {'char', 'string'}, {'scalartext'});
validateattributes(classStruct, {'struct'}, {'scalar'});
validateattributes(namespace, {'char', 'string'}, {'scalartext'});

[attr_props, attr_constructs, attr_readonly_constructs] = filterAttributes(classStruct);
[ds_props, ds_constructs, ds_readonly_constructs] = filterDatasets(classStruct);

%filter links
link_props = {};
link_constructs = struct();
if isfield(classStruct, 'links')
  link_props = fieldnames(classStruct.links);
  for link_prop=link_props'
    link_constructs.(link_prop{1}) = '[]';
  end
end

ds_props_flat = ds_props; %ds_props but with formatted property strings
for i=1:length(ds_props_flat)
  nm = ds_props_flat{i};
  if iscell(nm)
    ds_props_flat{i} = [nm{1} '_' nm{2}];
  end
end

hasgroups = isfield(classStruct, 'groups') && ~isempty(fieldnames(classStruct.groups));

nongroup_props = unique(cat(2, [link_props ds_props_flat attr_props]));
if length(nongroup_props) ~= sum([length(link_props) length(ds_props_flat) length(attr_props)])
  error(['writeClass: properties have conflicting names.', ...
    'Check all dataset/attribute/group names and <dataset>_<attribute> constructions for conflicting names.']);
end

fid = fopen(fullfile(namespace2dir(namespace), [className '.m']), 'w+');
fprintf(fid, 'classdef %s', className);
if isfield(classStruct, 'neurodata_type_inc')
  %we assume that the included objects includes 'handle' by default.
  imports = sprintf('%s.%s', namespace, classStruct.neurodata_type_inc);
else
  imports = 'types.untyped.MetaClass'; %root objects should import handle by default.
end
fprintf(fid, [' < %s' newline], imports);

%% property definitions
fprintf(fid, newline);
writeProps(fid, nongroup_props);

%% constructor
fprintf(fid, newline);
fprintf(fid, ['  methods %%constructor' newline]);
fprintf(fid, ['    function obj = %s(varargin)' newline], className);
fprintf(fid, ['      p = inputParser;' newline]);
fprintf(fid, ['      p.KeepUnmatched = true;' newline]);
%write optional params with defaults
for constructs={attr_constructs ds_constructs link_constructs}
  writeAddParam(fid, constructs{1}, 'spaces', 6);
end

if hasgroups
  writeAddParam(fid, struct('groups', 'struct()'), 'spaces', 6);
end
fprintf(fid, ['      p.parse(varargin{:});' newline]);
if isfield(classStruct, 'neurodata_type_inc')
  fprintf(fid, ['      obj = obj@%s.%s(varargin{:});' newline],...
    namespace, classStruct.neurodata_type_inc);
else
  fprintf(fid, ['      obj = obj@types.untyped.MetaClass(varargin{:});' newline]);
end

%set readonly values
writeAddReadonly(fid, attr_readonly_constructs, 'spaces', 6);
writeAddReadonly(fid, ds_readonly_constructs, 'spaces', 6);

%set Results assignment
fprintf(fid, ['      fn = fieldnames(p.Results);' newline]);
fprintf(fid, ['      if ~isempty(fn)' newline]);
fprintf(fid, ['        for fieldcell=fn''' newline]);
fprintf(fid, ['          field = fieldcell{1};' newline]);

if hasgroups
fprintf(fid, ['          if ~strcmp(field, ''groups'')' newline]);
fprintf(fid, '  '); %scoping space
end

fprintf(fid, ['          obj.(field) = p.Results.(field);' newline]);

if hasgroups
fprintf(fid, ['          end' newline']);
end

fprintf(fid, ['        end' newline]);
fprintf(fid, ['      end' newline]);
if hasgroups
  fprintf(fid, ['     gn = fieldnames(p.Results.groups);' newline]);
  fprintf(fid, ['      if ~isempty(gn)' newline]);
  fprintf(fid, ['        for groupcell=gn''' newline]);
  fprintf(fid, ['          gnm = groupcell{1};' newline]);
  fprintf(fid, ['          if isfield(obj, gnm)' newline]);
  fprintf(fid, ['            error(''Naming conflict found in %s object property name: ''''%%s'''''', gnm);' newline], className);
  fprintf(fid, ['          else' newline]);
  fprintf(fid, ['            addprop(obj, gnm);' newline]);
  fprintf(fid, ['            obj.(gnm) = p.Results.groups.(gnm);' newline']);
  fprintf(fid, ['          end' newline]);
  fprintf(fid, ['        end' newline]);
  fprintf(fid, ['      end' newline]);
end
fprintf(fid, ['    end' newline]);
fprintf(fid, ['  end' newline]);

%% setters
fprintf(fid, newline);
fprintf(fid, ['  methods %%setters' newline]);
fprintf(fid, ['  end' newline]);

%% validators
fprintf(fid, newline);
fprintf(fid, ['  methods(Access=protected) %%validators' newline]);
fprintf(fid, ['  end' newline]);

%% export
fprintf(fid, newline);
fprintf(fid, ['  methods  %%export' newline]);
fprintf(fid, ['    function export(obj, loc_id)' newline]);
if isfield(classStruct, 'neurodata_type_inc')
  fprintf(fid, ['      export@%s.%s(obj, loc_id);' newline],...
    namespace, classStruct.neurodata_type_inc);
else
  fprintf(fid, ['      export@types.untyped.MetaClass(obj, loc_id);' newline]);
end
%write attributes
for i=1:length(attr_props)
  nm = attr_props{i};
  file.writeExportFunction(fid, 'Attribute', nm, nm, classStruct.attributes.(nm).dtype,...
    'spaces', 6);
end
%write datasets
for i=1:length(ds_props)
  nm = ds_props{i};
  
  if ~iscell(nm)
    ds = classStruct.datasets.(nm);
    spacenum = 6;
    
    hasDependents = isfield(ds, 'attributes');
    if strcmp(ds.dtype, 'any')
      % in the Link edgecase, we don't write dependents, and just export Link
      fprintf(fid, [file.spaces(spacenum) 'if isa(obj.%s, ''types.untyped.Link'')' newline], nm);
      spacenum = spacenum + 2;
      fprintf(fid, [file.spaces(spacenum) 'export(obj.%s, loc_id, ''%s'');' newline], nm, nm);
      fprintf(fid, [file.spaces(spacenum - 2) 'else' newline]);
    end
    file.writeExportFunction(fid, 'Dataset', nm, nm, ds.dtype,...
      'spaces', spacenum, 'keepid', hasDependents);
    if hasDependents
      dsattrfn = fieldnames(ds.attributes);
      for j=1:length(dsattrfn)
        attrnm = dsattrfn{j};
        file.writeExportFunction(fid, 'Attribute', attrnm, [nm '_' attrnm],...
          ds.attributes.(attrnm).dtype, 'spaces', spacenum, 'idname', 'id');
      end
      fprintf(fid, [file.spaces(spacenum) 'H5D.close(id);' newline]);
    end
    if strcmp(ds.dtype, 'any')
      spacenum = spacenum - 2;
      fprintf(fid, [file.spaces(spacenum) 'end' newline]);
    end
  end
end
%write links
for i=1:length(link_props)
  lnm = link_props{i};
  fprintf(fid, ['      export(obj.%s, loc_id, ''%s'');' newline], lnm, lnm);
end

%write groups
if hasgroups
  fprintf(fid, ['      plist = ''H5P_DEFAULT'';' newline]);
  fprintf(fid, ['      for fnms=fieldnames(obj)''' newline]);
  fprintf(fid, ['        fnm = fnms{1};' newline]);
  fprintf(fid, ['        if startsWith(class(obj.(fnm)), ''types.'') && ~isa(obj.(fnm), ''types.untyped.Link'')' newline]);
  fprintf(fid, ['          gid = H5G.create(loc_id, fnm, plist, plist, plist);' newline]);
  fprintf(fid, ['          export(obj.(fnm), gid);' newline]);
  fprintf(fid, ['          H5G.close(gid);' newline]);
  fprintf(fid, ['        end' newline]);
  fprintf(fid, ['      end' newline]);
end

%% end
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
      ros.(nm) = file.dtype2val(attr.dtype, attr.value);
    else
      ps.(nm) = file.defaultFromStruct(attr);
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
      ros.(nm) = file.dtype2val(prop.dtype, prop.value);
    else
      ps.(nm) = file.defaultFromStruct(prop);
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

function writeAddParam(fid, def_struct, varargin)
file.writeDefStruct(fid, def_struct, 'p.addParameter(''%s'', %s);', varargin{:});
end

function writeAddReadonly(fid, def_struct, varargin)
file.writeDefStruct(fid, def_struct, 'obj.%s = %s;', varargin{:});
end

function dir = namespace2dir(namespace)
mapped = cellfun(@(s) ['+' s], split(namespace, '.'), 'UniformOutput', false);
dir = fullfile(mapped{:});
end