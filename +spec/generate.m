function generate(namespace_map, schema_map)
%GENERATE Generates MATLAB classes from namespace mappings.
% optionally, include schema mapping as second argument OR path of specs

namespace = spec.getNamespaceInfo(namespace_map);
if ischar(schema_map)
    schema = containers.Map;
    for i=1:length(namespace.filenames)
        filename = namespace.filenames{i};
        if ~endsWith(filename, '.yaml')
            filename = [filename '.yaml'];
        end
        fid = fopen(fullfile(schema_map, filename));
        schema(filename) = fread(fid, '*char') .';
        fclose(fid);
    end
    schema = spec.getSourceInfo(schema);
else
    schema = spec.getSourceInfo(schema_map);
end

extSchema = struct('name', namespace.name,...
    'schema', schema,...
    'dependencies', {namespace.dependencies},...
    'version', namespace.version);
namespacePath = 'namespaces';
if 7 ~= exist(namespacePath, 'dir')
    mkdir(namespacePath);
end

fullPath = fullfile(namespacePath, [extSchema.name '.mat']);
save(fullPath, '-struct', 'extSchema');

%check/load dependency namespaces
extmap = schemes.loadNamespace(extSchema.name);

%write files
file.writeNamespace(extmap(extSchema.name));
end

