function generate(namespace_map, schema_map)
%GENERATE Generates MATLAB classes from java mappings.
namespace = spec.getNamespaceInfo(namespace_map);
schema = spec.getSourceInfo(schema_map);

extSchema = struct('name', namespace.name,...
    'schema', schema,...
    'dependencies', {namespace.dependencies},...
    'version', namespace.version);
namespacePath = 'namespaces';
if 7 ~= exist(namespacePath, 'dir')
    mkdir(namespacePath);
end
save(fullfile(namespacePath,[extSchema.name '.mat']), '-struct', 'extSchema');

%check/load dependency namespaces
extmap = schemes.loadNamespace(extSchema.name);

%write files
file.writeNamespace(extmap(extSchema.name));
end

