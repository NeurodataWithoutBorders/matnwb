function Namespaces = generate(namespaceText, schemaSource)
%GENERATE Generates MATLAB classes from namespace mappings.
% optionally, include schema mapping as second argument OR path of specs
% schemaSource is either a path to a directory where the source is
% OR a containers.Map of filenames
Schema = spec.loadSchemaObject();
namespace = spec.schema2matlab(Schema.read(namespaceText));
Namespaces = spec.getNamespaceInfo(namespace);

for iInfo = 1:length(Namespaces)
    Namespaces(iInfo).namespace = namespace;
    if ischar(schemaSource) || isstring(schemaSource)
        schema = containers.Map;
        Namespace = Namespaces(iInfo);
        for iFilenames = 1:length(Namespace.filenames)
            filenameStub = Namespace.filenames{iFilenames};
            filename = [filenameStub '.yaml'];
            schema(filenameStub) = fileread(fullfile(schemaSource, filename));
        end
        schema = spec.getSourceInfo(schema);
    else % map of schemas with their locations
        schema = spec.getSourceInfo(schemaSource);
    end
    Namespaces(iInfo).schema = schema;
end

end