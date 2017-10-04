function writeClass(className, classStruct, dir)
validateattributes(className, {'char', 'string'}, {'scalartext'});
validateattributes(classStruct, {'struct'}, {'scalar'});
validateattributes(dir, {'char', 'string'}, {'scalartext'});

attr_props = {};
% name => default_value
attr_constructs = struct();
% name => value
attr_readonly_constructs = struct();

if isfield(classStruct, 'attributes')
  attr_props = fieldnames(classStruct, 'attributes');
  
  for i=1:length(attr_props)
    nm = attr_props{i};
    attr = classStruct.attributes.(nm);
    if isfield(attr, 'value')
      attr_readonly_constructs.(nm) = dtype2val(attr.dtype, attr.value);
    else
      attr_constructs.(nm) = defaultFromStruct(attr);
    end
  end
end

ds_props = {};
% name => default_value
ds_constructs = struct();
% name => value
ds_readonly_constructs = struct();

if isfield(classStruct, 'datasets')
  ds_props = fieldnames('datasets');
  
  %construct names for dependent properties(i.e. attributes in datasets)
  for i=1:length(ds_props)
    nm = ds_props{i};
    ds = classStruct.datasets.(nm);
    
    if isfield(ds, 'attributes')
      subattr = fieldnames(ds.attributes);
      for j=1:length(subattr)
        %set as two cell arrays
        ds_props{length(ds_props)+1} = {nm subattr{j}};
      end
    end
  end
  
  %constructor creation.
  for i=1:length(ds_props)
    nm = ds_props{i}; %can be multiple sizes
    if iscell(nm)
      prop = classStruct.datasets.(nm{1}).attributes.(nm{2});
      nm = [nm{1} '_' nm{2}]; %concatenate w/ underscore <dataset>_<attribute>
      ds_props{i} = nm;
    else
      prop = classStruct.datasets.(nm);
    end
    
    if isfield(prop, 'value')
      ds_readonly_constructs.(nm) = dtype2val(prop.dtype, prop.value);
    else
      ds_constructs.(nm) = defaultFromStruct(prop);
    end
  end
end

link_props = {};
if isfield(classStruct, 'links')
  link_props = fieldnames(classStruct.links);
end

if length(union(link_props, union(ds_props, attr_props))) ~= sum([length(link_props) length(ds_props) length(attr_props)])
  error(['writeClass: properties and dataset attributes have conflicting names.', ...
    'Check all property names and <dataset>_<attribute> constructions for conflicting names.']);
end

hasgroups = isfield(classStruct, 'groups');

%batch into export and definitions for attributes/datasets/links/groups
fid = fopen(fullfile(dir, className));
fprintf(fid, 'classdef %s', className);
if isfield(classStruct, 'neurodata_type_inc')
  fprintf(fid, ' < %s', classStruct.neurodata_type_inc);
end

%def
if ~isempty(attr_props)
  fprintf(fid, newline);
  writeProps(fid, attr_props);
end

if ~isempty(ds_props)
  fprintf(fid, newline);
  writeProps(fid, ds_props);
end

if ~isempty(link_props)
  fprintf(fid, newline);
  writeProps(fid, link_props);
end

%groups
if hasgroups
  fprintf(fid, newline);
  writeProps(fid, {'groups'});
end

%constructor
fprintf(fid, newline);
fprintf(fid, ['  methods' newline]);
fprintf(fid, ['    function obj = %s(varargin)' newline], className);
fprintf(fid, ['      p = inputParsers;' newline]);
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
  fprintf(fid, ['      obj = obj@types.%s(varargin{:});' newline],...
    classStruct.neurodata_type_inc);
end

%write properties with value non-default_value
writeAddReadonly(fid, attr_readonly_constructs, 'spaces', 6);
writeAddReadonly(fid, ds_readonly_constructs, 'spaces', 6);

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
fprintf(fid, ['  methods' newline]);
fprintf(fid, ['  end' newline]);

%validators
fprintf(fid, newline);
fprintf(fid, ['  methods(Access=protected)' newline]);
fprintf(fid, ['  end' newline]);

%export
fprintf(fid, newline);
fprintf(fid, ['  methods' newline]);
fprintf(fid, ['    function export(obj, loc_id)' newline]);
fprintf(fid, ['      export@%s(obj, loc_id);' newline], classStruct.neurodata_type_inc);
%write attributes
%write datasets
%write links
%write groups
fprintf(fid, ['    end' newline]);
fprintf(fid, ['  end' newline]);
fprintf(fid, 'end');
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
  val = dtype2val(s.dtype, val);
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