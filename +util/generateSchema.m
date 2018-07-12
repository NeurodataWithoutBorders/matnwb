function namespace = generateSchema(source)
%find jar from source
matnwbDir = fileparts(which('nwbfile'));
javaaddpath(fullfile(matnwbDir, 'jar', 'schema.jar'));
[localpath, ~, ~] = fileparts(source);
[filenames, nm, dep] = yaml.getNamespaceInfo(source);
schema = yaml.getSourceInfo(localpath, filenames{:});
namespace = struct('name', nm, 'schema', schema, 'dependencies', {dep});
end