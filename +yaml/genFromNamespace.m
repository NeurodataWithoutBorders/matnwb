function [classes, name, depends] = genFromNamespace(path) %path to namespace yaml file
validateattributes(path, {'char', 'string'}, {'scalartext'});
[fileList, name, depends] = parseNamespace(path);
[dirname, ~, ~] = fileparts(path);
classes = struct();
for file=fileList
  yml = yaml.parseClass(fullfile(dirname, file{1}), name);
  classes = util.structUniqUnion(classes, yml);
end
end

function [filelist, name, depends] = parseNamespace(fp)
% add the local java path 
cwd=fileparts(mfilename('fullpath'));
javaaddpath(fullfile(cwd,'..','jar','schema.jar'));
% do our buisiness
schema = Schema;
filelist = {};
depends = {};
yamlobj = schema.read(fp);
nmscell = cell(yaml.util.hashmap2struct(yamlobj).namespaces.toArray());
nms = yaml.util.hashmap2struct(nmscell{1});
name = nms.name;
schema = cell(nms.schema.toArray());
for entry=schema'
  hm = yaml.util.hashmap2struct(entry{1});
  if isfield(hm, 'source')
    filelist{length(filelist)+1} = hm.source;
  elseif isfield(hm, 'namespace')
    depends{length(depends)+1} = hm.namespace;
  end
end
end