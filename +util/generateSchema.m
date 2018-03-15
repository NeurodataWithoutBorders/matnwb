function namespace = generateSchema(source)
javaaddpath(fullfile('jar', 'schema.jar'));
[localpath, ~, ~] = fileparts(source);
[filenames, nm, dep] = yaml.getNamespaceInfo(source);
schema = yaml.getSourceInfo(localpath, filenames{:});
namespace = struct();
namespace.name = nm;
namespace.schema = schema;
namespace.dependencies = dep;
end