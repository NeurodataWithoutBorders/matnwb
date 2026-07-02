function propertyName = getPropertyNameForSchemaName(mapping, schemaName)
% getPropertyNameForSchemaName - Map a schema name to its property identifier
%
% Given a SchemaPropertyNameMapping struct (see
% io.internal.getSchemaPropertyNameMapping), return the property identifier for
% schemaName, or schemaName unchanged when it is not a remapped reserved-keyword
% name (including when mapping is empty).
    propertyName = schemaName;
    if isempty(mapping)
        return
    end
    propertyIdentifiers = fieldnames(mapping);
    schemaNames = struct2cell(mapping);
    isMatch = strcmp(schemaNames, schemaName);
    if any(isMatch)
        propertyName = propertyIdentifiers{find(isMatch, 1)};
    end
end
