function namespace = generateSchema(source)
%find jar from source
matnwbDir = fileparts(which('nwbfile'));
javaaddpath(fullfile(matnwbDir, 'jar', 'schema.jar'));
[localpath, ~, ~] = fileparts(source);
[filenames, nm, dep] = yaml.getNamespaceInfo(source);
schema = yaml.getSourceInfo(localpath, filenames{:});
if isempty(dep)
    % struct confuses {} as an empty struct for some reason
    dep = [];
end
namespace = struct('name', nm, 'schema', schema, 'dependencies', dep);
end