function schemaName = getSchemaNameForPropertyName(mapping, propertyName)
% getSchemaNameForPropertyName - Map a property identifier to its schema name
%
% Given a SchemaPropertyNameMapping struct (see
% io.internal.getSchemaPropertyNameMapping), return the schema name for
% propertyName, or propertyName unchanged when it is not a remapped
% reserved-keyword identifier (including when mapping is empty).
    schemaName = propertyName;
    if ~isempty(mapping) && isfield(mapping, propertyName)
        schemaName = mapping.(propertyName);
    end
end
