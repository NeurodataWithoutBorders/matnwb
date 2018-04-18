function nwb = nwbRead(filename)
%NWBREAD Reads an NWB file.
%  nwb = nwbRead(filename) Reads the nwb file at filename and returns an
%  NWBFile object representing its contents.
%  
%  Requires that core and extension NWB types have been generated
%  and reside in a 'types' package on the matlab path.
%  
%  Example: 
%    %Generate Matlab code for the NWB objects from the core schema.
%    %This only needs to be done once.
%    generateCore('schema\core\nwb.namespace.yaml');
%    %Now we can read nwb files!
%    nwb=nwbRead('data.nwb');
%  
%  See also GENERATECORE, GENERATEEXTENSIONS, NWBFILE, NWBEXPORT
validateattributes(filename, {'char', 'string'}, {'scalartext'});
info = h5info(filename);

[nwb, links, refs] = io.parseGroups(filename, info);

% we need full filepath to process this part.
if java.io.File(filename).isAbsolute
  ff = filename;
else
  ff = fullfile(pwd, filename);
end
[fp, ~, ~] = fileparts(ff); %complete filepath

for lref = linkRefs
  lr = lref{1};
  if isempty(lr.filename)
    lr.ref = nwb(lr.path);
  else
    % we assume the external reference is to a dataset.
    if ~java.io.File(lr.filename).isAbsolute
      lr.filename = fullfile(fp, lr.filename);
    end
    lr.ref = h5read(lr.filename, lr.path);
  end
end
end

function s = process(propList, func)
validateattributes(propList, {'struct', 'util.StructMap'}, {'vector'});
s = util.StructMap();
for i=1:length(propList)
  if isstruct(propList)
    prop = util.StructMap(propList(i));
  else
    prop = propList(i);
  end
  path = prop.Name;
  v = func(prop);
  if isa(v, 'util.StructMap')
    s = util.structUniqUnion(s, v);
  elseif isa(v, 'nwbfile')
    s = v; %Return completed NWBFile
  else
    s.(path2name(path)) = v;
  end
end
end

function [object, linkRefs] = processGroups(glist, filename)
  function v = procFun(g)
    go = util.StructMap;
    
    if ~isempty(g.Attributes)
      go.attributes = processAttributes(g.Attributes);
    end
    
    if ~isempty(g.Groups)
      [go.groups, lr] = processGroups(g.Groups, filename);
      for gnm=fieldnames(go.groups)'
        nm = gnm{1};
        %move classes to their own section
        if ~isa(go.groups.(nm), 'types.untyped.Group')
          tmp = go.groups.(nm);
          go.groups = rmfield(go.groups, nm);
          if isempty(fieldnames(go.groups))
            go = rmfield(go, 'groups');
          end
          if ~isfield(go, 'classes')
            go.classes = util.StructMap;
          end
          goclasses = go.classes;
          goclasses.(nm) = tmp;
          go.classes = goclasses;
        end
      end
      linkRefs = [linkRefs lr];
    end
    
    if ~isempty(g.Datasets)
      go.datasets = processDatasets(g.Datasets, g.Name,filename);
    end
    
    if ~isempty(g.Links)
      go.links = processLinks(g.Links);
      %create list of link references
      for linkname=fieldnames(go.links)'
        ln = linkname{1};
        linkRefs{length(linkRefs)+1} = go.links.(ln);
      end
    end
    
    %check if group should actually be a type
    if isfield(go, 'attributes') && isfield(go.attributes, 'neurodata_type')
      slist = {};
      for fields={'attributes' 'datasets' 'links'}
        fnm = fields{1};
        if isfield(go, fnm)
          slist{length(slist)+1} = go.(fnm);
        end
      end
      kwa = struct2kwargs(slist{:});
      if isfield(go, 'groups') || isfield(go, 'classes')
        if isfield(go, 'groups')
          gogroups = go.groups;
        else
          gogroups = util.StructMap;
        end
        
        if isfield(go, 'classes')
          goclasses = go.classes;
        else
          goclasses = util.StructMap;
        end
        
        groups = util.structUniqUnion(gogroups, goclasses);
        kwa = cat(2, kwa, {'groups' groups});
      end
      ndata_type = go.attributes.neurodata_type;
      if strcmp(ndata_type{1}, 'NWBFile') %initialize the inherited object instead.
        dt = 'nwbfile';
      else
        dt = ['types.' ndata_type{1}];
      end
      v = feval(dt, kwa{:});
    else
      v = types.untyped.Group(go);
    end
  end
linkRefs = {};
object = process(glist, @procFun);
end

function attrobj = processAttributes(alist)
attrobj = process(alist, @(a) a.Value);
end

function dsobj = processDatasets(dlist, path, filename)
  function v = procFun(d)
    fp = [path '/' d.Name];
    if isempty(d.Attributes)
      v = h5read(filename, fp);
    else
      v = processAttributes(d.Attributes);
      for afields=fieldnames(v)'
        af = afields{1};
        v.([d.Name '_' af]) = v.(af);
        v = rmfield(v, af);
      end
      v.(d.Name) = h5read(filename, fp);
    end
  end
dsobj = process(dlist, @procFun);
end

function lnkobj = processLinks(llist)
  function v = procFun(l)
    % for some reason, h5info returns links in order {optional[<filename>]; path}
    % So we flipud() the value so that it represents function args properly.
    data = flipud(l.Value); 
    v = types.untyped.Link(data{:});
  end
lnkobj = process(llist, @procFun);
end

function nm = path2name(path)
validateattributes(path, {'char', 'string'}, {'scalartext'});
splitpath = strsplit(path, '/');
nm = splitpath{end};
end

function kwa = struct2kwargs(varargin)
kwa = {};
for n=1:nargin
  s = varargin{n};
  validateattributes(s, {'util.StructMap'}, {'scalar'});
  
  fnms = fieldnames(s);
  offset = length(kwa);
  kwa = cat(2, kwa, cell(1, length(fnms)*2));
  for i=1:length(fnms)
    fnm = fnms{i};
    kwa{i*2-1+offset} = fnm;
    kwa{i*2+offset} = s.(fnm);
  end
end
end