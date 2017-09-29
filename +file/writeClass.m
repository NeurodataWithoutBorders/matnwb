function writeClass(className, classStruct, dir)
validateattributes(className, {'char', 'string'}, {'scalartext'});
validateattributes(classStruct, {'struct'}, {'scalar'});
validateattributes(dir, {'char', 'string'}, {'scalartext'});

%batch into export and definitions for attributes/datasets/links/groups
fid = fopen(fullfile(dir, className));
fprintf(fid, 'classdef %s', className);
if isfield(classStruct, 'neurodata_type_inc')
  fprintf(fid, ' < %s', classStruct.neurodata_type_inc);
end
fprintf(fid, newline);

allprops = {};
%def
%attributes
if isfield(classStruct, 'attributes')
  allprops = fieldnames(classStruct.attributes);
  writeProps(fid, allprops);
end
%datasets + dataset attributes
if isfield(classStruct, 'datasets')
  fprintf(fid, newline);
  fn = fieldnames(classStruct.datasets);
  allfn = fn;
  for i=1:length(fn)
    if isfield(classStruct.datasets.(fn{i}), 'attributes')
      subattr = fieldnames(classStruct.datasets.(fn{i}).attributes);
      for j=1:length(subattr)
        allfn{length(allfn)+1} = [fn{i} '_' subattr{j}];
      end
    end
  end
  writeProps(fid, allfn);
  temp_allprops = union(allprops, allfn);
  if length(temp_allprops) < length(allprops) + length(allfn)
    s = dbstack();
    error('%s: line %s: Naming conflict found between either attributes, datasets, or links',...
      s(1).file, s(1).name);
  else
    allprops = temp_allprops;
  end
end
%links
if isfield(classStruct, 'links')
  fprintf(fid, newline);
  fn = fieldnames(classStruct.links);
  writeProps(fid, fn);
  temp_allprops = union(allprops, fn);
  if length(temp_allprops) < length(allprops) + length(fn)
    s = dbstack();
    error('%s: line %s: Naming conflict found between either attributes, datasets, or links',...
      s(1).file, s(1).name);
  else
    allprops = temp_allprops;
  end
end

%groups
if isfield(classStruct, 'groups')
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
%attributes
if isfield(classStruct, 'attributes')
  attrnms = fieldnames(classStruct.attributes);
  for i=1:length(attrnms)
    nm = attrnms{i};
    attr = classStruct.attributes.(nm);
    if ~isfield(attr, 'value')
      fprintf(fid, ['      p.addParameter(''%s'', %s);' newline],...
        nm, defaultFromStruct(attr));
    end
  end
end
%datasets
if isfield(classStruct, 'datasets')
  dsnms = fieldnames(classStruct.datasets);
  for i=1:length(dsnms)
    nm = dsnms{i};
    ds = classStruct.datasets.(nm);
    if ~isfield(ds, 'value')
      fprintf(fid, ['      p.addParameter(''%s'', %s);' newline],...
        nm, defaultFromStruct(ds));
    end
  end
end
%links
if isfield(classStruct, 'links')
  linknms = fieldnames(classStruct.links);
  for i=1:length(linknms)
    fprintf(fid, ['      p.addParameter(''%s'', []);' newline], linknms);
  end
end
fprintf(fid, ['      p.addParameter(''groups'', struct());' newline]);
fprintf(fid, ['      p.parse(varargin{:});' newline]);
if isfield(classStruct, 'neurodata_type_inc')
  fprintf(fid, ['      obj = obj@types.%s(varargin{:});' newline],...
    classStruct.neurodata_type_inc);
end

%write properties with value non-default_value
%attributes
if isfield(classStruct, 'attributes')
  attrnms = fieldnames(classStruct.attributes);
  for i=1:length(attrnms)
    nm = attrnms{i};
    attr = classStruct.attributes.(nm);
    if isfield(attr, 'value')
      fprintf(fid, ['      obj.%s = %s;' newline],...
        nm, dtype2val(attr.dtype, attr.value));
    end
  end
end
%datasets
if isfield(classStruct, 'datasets')
  dsnms = fieldnames(classStruct.datasets);
  for i=1:length(dsnms)
    nm = dsnms{i};
    ds = classStruct.datasets.(nm);
    if isfield(ds, 'value')
      fprintf(fid, ['      obj.%s = %s;' newline],...
        nm, dtype2val(ds.dtype, ds.value));
    end
  end
end

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