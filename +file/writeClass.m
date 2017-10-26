function writeClass(className, classStruct, namespace)
validateattributes(className, {'char', 'string'}, {'scalartext'});
validateattributes(classStruct, {'struct'}, {'scalar'});
validateattributes(namespace, {'char', 'string'}, {'scalartext'}); %filepath to write to.  NOT NWB NAMESPACE

[attr_props, attr_constructs, attr_readonly_constructs, attr_inherited] = filterAttributes(classStruct);
[ds_props, ds_constructs, ds_readonly_constructs, ds_inherited] = filterDatasets(classStruct);
[group_props, group_constructs, group_inherited, hasAnon] = filterGroups(classStruct);

hasgroups = ~isempty(group_props) || ~isempty(group_inherited) || hasAnon;

%filter links
link_props = {};
link_constructs = struct();
if isfield(classStruct, 'links')
  link_props = fieldnames(classStruct.links)';
  for link_prop=link_props
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

preset_props = unique(horzcat(link_props, ds_props_flat, attr_props, group_props));
if length(preset_props) ~= sum([length(link_props) length(ds_props_flat) length(attr_props) length(group_props)])
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

% Write documentation string
if isfield(classStruct, 'doc')
  fprintf(fid, ['%% %s %s' newline], className, classStruct.doc);
end

%% property definitions
fprintf(fid, newline);
fprintf(fid, ['  properties' newline]);
%datasets
if ~isempty(ds_props)
  for i=1:length(ds_props)
    ds_prop = ds_props{i};
    if iscell(ds_prop) % is a dependent property
      ds_struct = classStruct.datasets.(ds_prop{1}).attributes.(ds_prop{2});
      ds_prop = ds_props_flat{i};
    else
      ds_struct = classStruct.datasets.(ds_prop);
    end
    if isfield(ds_struct, 'doc')
      docstr = ds_struct.doc;
    else
      docstr = '';
    end
    fprintf(fid, ['    %s; %% %s' newline], ds_prop, docstr);
  end
end
%attributes
if ~isempty(attr_props)
  writeProps(fid, attr_props, classStruct.attributes);
end

%links
if ~isempty(link_props)
  writeProps(fid, link_props, classStruct.links);
end

%groups
if ~isempty(group_props)
  writeProps(fid, group_props, classStruct.groups);
end

fprintf(fid, ['  end' newline]);
%% constructor
fprintf(fid, newline);
fprintf(fid, ['  methods %%constructor' newline]);
fprintf(fid, ['    function obj = %s(varargin)' newline], className);
fprintf(fid, ['      p = inputParser;' newline]);
fprintf(fid, ['      p.KeepUnmatched = true;' newline]);
%write optional params with defaults
%note: group_constructs are a special case because they will never be a kwarg
%      They are actually assigned below with the group extensions but we allow
%      this 'optional' parameter for the sake of setting default value.
for constructs={attr_constructs ds_constructs link_constructs group_constructs}
  writeAddParam(fid, constructs{1}, 'spaces', 6);
end

%allow group extension
if hasgroups 
  writeAddParam(fid, struct('groups', 'struct()'), 'spaces', 6);
end
fprintf(fid, ['      p.parse(varargin{:});' newline]);
if isfield(classStruct, 'neurodata_type_inc')
  fprintf(fid, ['      hastypename = false;' newline]);
  fprintf(fid, ['      hasnamespace = false;' newline]);
  fprintf(fid, ['      for arg = varargin' newline]);
  fprintf(fid, ['        if iscellstr(arg)' newline]);
  fprintf(fid, ['          switch arg{1}' newline]);
  fprintf(fid, ['            case ''neurodata_type''' newline]);
  fprintf(fid, ['              hastypename = true;' newline]);
  fprintf(fid, ['            case ''namespace''' newline]);
  fprintf(fid, ['              hasnamespace = true;' newline]);
  fprintf(fid, ['          end' newline]);
  fprintf(fid, ['        end' newline]);
  fprintf(fid, ['      end' newline]);
  fprintf(fid, ['      if ~hastypename' newline]);
  fprintf(fid, ['        varargin{length(varargin)+1} = ''neurodata_type'';' newline]);
  fprintf(fid, ['        varargin{length(varargin)+1} = {''%s''};' newline], className);
  fprintf(fid, ['      end' newline]);
  fprintf(fid, ['      if ~hasnamespace' newline]);
  fprintf(fid, ['        varargin{length(varargin)+1} = ''namespace'';' newline]);
  fprintf(fid, ['        varargin{length(varargin)+1} = {''%s''};' newline], classStruct.namespace);
  fprintf(fid, ['      end' newline]);
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
  fprintf(fid, ['          if ~isprop(obj, gnm)' newline]);
  fprintf(fid, ['            addprop(obj, gnm);' newline]);
  fprintf(fid, ['          end' newline]);
  fprintf(fid, ['          obj.(gnm) = p.Results.groups.(gnm);' newline]);
  fprintf(fid, ['        end' newline]);
  fprintf(fid, ['      end' newline]);
end
fprintf(fid, ['    end' newline]);
fprintf(fid, ['  end' newline]);

%% setters
fprintf(fid, newline);
fprintf(fid, ['  methods %%setters' newline]);
if ~isempty(preset_props)
  for ngprop = preset_props
    ngp = ngprop{1};
    fprintf(fid, ['    function obj = set.%s(obj, val)' newline], ngp);
    fprintf(fid, ['      obj.%s = validate_%s(obj, val);' newline], ngp, ngp);
    fprintf(fid, ['    end' newline]);
  end
end
fprintf(fid, ['  end' newline]);

%% validators
fprintf(fid, newline);
fprintf(fid, ['  methods(Access=protected) %%validators' newline]);
%attributes
allattr = horzcat(attr_props, attr_inherited);
if ~isempty(allattr)
  for aprop=allattr
    ap = aprop{1};
    attr_s = classStruct.attributes.(ap);
    fprintf(fid, ['    function val = validate_%s(~, val)' newline], ap);
    if strcmp(attr_s.dtype, 'string')
      fprintf(fid, ['      if ~iscellstr(val)' newline]);
      fprintf(fid, ['        error(''%s: %s must be a cell string'');' newline], className, ap);
      fprintf(fid, ['      end' newline]);
    else
      fprintf(fid, ['      if ~isempty(val)' newline]);
      if startsWith(attr_s.dtype, 'double') || startsWith(attr_s.dtype, 'single')
        fprintf(fid, ['        if realmax(''%s'') < val' newline], attr_s.dtype);
      else
        fprintf(fid, ['        if intmax(''%s'') < val' newline], attr_s.dtype);
      end
      fprintf(fid, ['          warning(''%s: property %s overflow'');' newline], className, ap);
      if startsWith(attr_s.dtype, 'double') || startsWith(attr_s.dtype, 'single')
        fprintf(fid, ['        elseif (-realmax(''%s'')) > val' newline], attr_s.dtype);
      else
        fprintf(fid, ['        elseif intmin(''%s'') > val' newline], attr_s.dtype);
      end
      fprintf(fid, ['          warning(''%s: property %s underflow'');' newline], className, ap);
      fprintf(fid, ['        end' newline]);
      fprintf(fid, ['      end' newline]);
      fprintf(fid, ['      val = %s(val);' newline], attr_s.dtype);
    end
    fprintf(fid, ['    end' newline]);
  end
end
%datasets
allds = horzcat(ds_props, ds_inherited);
if ~isempty(allds)
  for dsprop=allds
    dsp = dsprop{1};
    if iscell(dsp)
      ds_s = classStruct.datasets.(dsp{1}).attributes.(dsp{2});
      dsp = [dsp{1} '_' dsp{2}];
    else
      ds_s = classStruct.datasets.(dsp);
    end
    fprintf(fid, ['    function val = validate_%s(obj, val)' newline], dsp);
    fprintf(fid, ['      if isa(val, ''types.untyped.Link'')' newline]);
    fprintf(fid, ['        val.ref = validate_%s(obj, val.ref);' newline], dsp);
    fprintf(fid, ['        return;' newline]);
    fprintf(fid, ['      end' newline]);
    
    if isfield(ds_s, 'shape')
      % check lengths and dimensions
      if iscell(ds_s.shape{1})
        threshold = zeros(length(ds_s.shape), 1);
        nonNullIndices = cell(length(ds_s.shape), 1);
        for i = 1:length(ds_s.shape)
          threshold(i) = length(ds_s.shape{i});
          nonNullIndices{i} = find(~strcmp(ds_s.shape{i}, 'null'));
        end
        threshold = unique(threshold);
      else
        threshold = length(ds_s.shape);
        nonNullIndices = {find(~strcmp(ds_s.shape, 'null'))};
      end
      
      fprintf(fid, ['      if ~isempty(val)' newline]);
      fprintf(fid, '        if ');
      for i=1:length(threshold)
        if i > 1
          fprintf(fid, ' || ');
        end
        if threshold(i) > 2
          fprintf(fid, 'ndims(val) ~= %d', threshold(i));
        elseif threshold(i) > 1
          fprintf(fid, '~ismatrix(val)');
        else
          fprintf(fid, '~isvector(val)');
        end
      end
      fprintf(fid, newline);
      fprintf(fid, ['          error(''%s.%s: val must have [%s] dimensions'');' newline],...
        className, dsp, string(join(split(num2str(threshold')), ',')));
      fprintf(fid, ['        end' newline]);
      
      %check actual dimensions if shape has non-'null' values
      if any(~cellfun(@isempty, nonNullIndices))
        fprintf(fid, ['        switch ndims(val)' newline]);
        for i=1:length(threshold)
          if ~isempty(nonNullIndices{i})
            fprintf(fid, ['          case %d' newline], threshold(i));
            fprintf(fid, '            if ');
            for j=1:length(nonNullIndices{i})
              if j > 1
                fprintf(fid, ' || ');
              end
              index = nonNullIndices{i}(j);
              if iscell(ds_s.shape{1})
                shapesz = ds_s.shape{i}{index};
              else
                shapesz = ds_s.shape{index};
              end
              fprintf(fid, 'size(val, %d) ~= %s', index, shapesz);
            end
            if iscell(ds_s.shape{1})
              expectedShape = ds_s.shape{i};
            else
              expectedShape = ds_s.shape;
            end
            fprintf(fid, [newline file.spaces(14) 'error(''%s.%s: val must have shape [%s]'');' newline],...
              className, dsp, string(join(strrep(expectedShape, 'null', '~'), ',')));
            fprintf(fid, [file.spaces(12) 'end' newline]);
          end
        end
        fprintf(fid, ['        end' newline]);
      end
      fprintf(fid, ['      end' newline]);
    end
    switch(ds_s.dtype)
      case 'string'
        fprintf(fid, ['      if ~iscellstr(val)' newline]);
        fprintf(fid, ['        error(''%s: %s must be a cell string'');' newline], className, dsp);
        fprintf(fid, ['      end' newline]);
      case 'any'
      otherwise %numeric
        fprintf(fid, ['      if ~isempty(val)' newline]);
        if startsWith(ds_s.dtype, 'double') || startsWith(ds_s.dtype, 'single')
          fprintf(fid, ['        if realmax(''%s'') < val' newline], ds_s.dtype);
        else
          fprintf(fid, ['        if intmax(''%s'') < val' newline], ds_s.dtype);
        end
        fprintf(fid, ['          warning(''%s: property %s overflow'');' newline], className, dsp);
        if startsWith(ds_s.dtype, 'double') || startsWith(ds_s.dtype, 'single')
          fprintf(fid, ['        elseif (-realmax(''%s'')) > val' newline], ds_s.dtype);
        else
          fprintf(fid, ['        elseif intmin(''%s'') > val' newline], ds_s.dtype);
        end
        fprintf(fid, ['          warning(''%s: property %s underflow'');' newline], className, dsp);
        fprintf(fid, ['        end' newline]);
        fprintf(fid, ['      end' newline]);
        fprintf(fid, ['      val = %s(val);' newline], ds_s.dtype);
    end
    fprintf(fid, ['    end' newline]);
  end
end
%links
for lprop = link_props
  lp = lprop{1};
  fprintf(fid, ['    function val = validate_%s(~, val)' newline], lp);
  fprintf(fid, ['      if ~isempty(val) && ~isa(val, ''types.untyped.Link'')' newline]);
  fprintf(fid, ['        error(''%s: %s must be a Link object'');' newline], className, lp);
  fprintf(fid, ['      end' newline]);
  fprintf(fid, ['    end' newline]);
end

%groups
for gprop = group_props
  gp = gprop{1};
  fprintf(fid, ['    function val = validate_%s(~, val)' newline], gp);
  fprintf(fid, ['      if ~isa(val, ''types.untyped.Group'')' newline]);
  fprintf(fid, ['        error(''%s: %s must be a Group object'');' newline], className, gp);
  fprintf(fid, ['      end' newline]);
  fprintf(fid, ['    end' newline]);
end

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

function [propList, paramStruct, readOnlyStruct, inheritedList] = filterProperties(s, propname, filterFcn)
validateattributes(propname, {'string', 'char'}, {'scalartext'});
validateattributes(s, {'struct'}, {'scalar'});

propList = {};
paramStruct = struct();
readOnlyStruct = struct();
inheritedList = {};

if isfield(s, propname)
  fn = fieldnames(s.(propname));
  for i=1:length(fn)
    [propList, paramStruct, readOnlyStruct, inheritedList] = filterFcn(s, fn{i}, propList, paramStruct, readOnlyStruct, inheritedList);
  end
end
end

function writeProps(fid, nmlist, propstruct)
for nmprop = nmlist
  p = nmprop{1};
  p_struct = propstruct.(p);
  if isfield(p_struct, 'doc')
    docstr = p_struct.doc;
  else
    docstr = '';
  end
  fprintf(fid, ['    %s; %% %s' newline], p, docstr);
end
end

function [propList, paramStruct, readOnlyStruct, inheritedList] = filterAttributes(s)
  function [pl, ps, ros, inher] = filter(s, nm, pl, ps, ros, inher)
    attr = s.attributes.(nm);
    if attr.inherited
      inher{length(inher)+1} = nm;
    else
      pl{length(pl)+1} = nm;
    end
    
    if isfield(attr, 'value')
      ros.(nm) = file.dtype2val(attr.dtype, attr.value);
    else
      ps.(nm) = file.defaultFromStruct(attr);
    end
  end
[propList, paramStruct, readOnlyStruct, inheritedList] = filterProperties(s, 'attributes', @filter);
end

function [propList, paramStruct, readOnlyStruct, inheritedList] = filterDatasets(s)
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

  function [pl, ps, ros, inher] = filter(s, nm, pl, ps, ros, inher)
    ds = s.datasets.(nm);
    if ds.inherited
      inher{length(inher)+1} = nm;
    else
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
[propList, paramStruct, readOnlyStruct, inheritedList] = filterProperties(s, 'datasets', @filter);
end

function [propList, paramStruct, inheritedList, hasAnon] = filterGroups(s)
  function [pl, ps, ros, inher] = filter(s, nm, pl, ps, ros, inher)
    g = s.groups.(nm);
    if regexp(nm, '^Anon_\d+$')
      hasAnon = true;
    else
      if g.inherited
        inher{length(inher)+1} = nm;
      else
        pl{length(pl)+1} = nm;
        ps.(nm) = 'types.untyped.Group';
      end
    end
  end
hasAnon = false;
[propList, paramStruct, ~, inheritedList] = filterProperties(s, 'groups', @filter);
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