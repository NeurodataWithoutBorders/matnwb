function NamespaceInfo = generate(namespaceText, schemaSource)
%GENERATE Generates MATLAB classes from namespace mappings.
% optionally, include schema mapping as second argument OR path of specs
% schemaSource is either a path to a directory where the source is
% OR a containers.Map of filenames
Schema = spec.loadSchemaObject();
namespace = spec.schema2matlab(Schema.read(namespaceText));
NamespaceInfo = spec.getNamespaceInfo(namespace);
NamespaceInfo.namespace = namespace;

validateattributes(schemaSource, {'containers.Map', 'char', 'string'}, {});

if isa(schemaSource, 'containers.Map')
    % this is a map of schemas provided by an cached specification.
    schema = spec.getSourceInfo(schemaSource);
else
    schema = containers.Map;
    for i=1:length(NamespaceInfo.filenames)
        filenameStub = NamespaceInfo.filenames{i};
        filename = [filenameStub '.yaml'];
        fid = fopen(fullfile(schemaSource, filename));
        schema(filenameStub) = fread(fid, '*char') .';
        fclose(fid);
    end
    schema = spec.getSourceInfo(schema);
end

NamespaceInfo.schema = schema;
end