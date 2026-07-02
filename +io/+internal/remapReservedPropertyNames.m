function propMap = remapReservedPropertyNames(typeName, propMap)
% remapReservedPropertyNames - Translate on-disk names to MATLAB property names
%
% Some schema field names are reserved MATLAB keywords (e.g. "events") and are
% therefore stored under a valid identifier on the generated class (e.g.
% "events_"). Each such class declares the identifier-to-schema-name mapping in
% its SchemaPropertyNameMapping constant property. This function renames the
% keys in propMap from their schema names to the corresponding property
% identifiers, so they match the class properties and constructor arguments.
%
% Classes without reserved-keyword properties have no mapping and propMap is
% returned unchanged.
    arguments
        typeName (1,:) char
        propMap containers.Map
    end

    mapping = io.internal.getSchemaPropertyNameMapping(typeName);
    if isempty(mapping)
        return
    end

    propertyIdentifiers = fieldnames(mapping);
    for i = 1:numel(propertyIdentifiers)
        propertyIdentifier = propertyIdentifiers{i};
        schemaName = mapping.(propertyIdentifier);
        if isKey(propMap, schemaName)
            propMap(propertyIdentifier) = propMap(schemaName);
            remove(propMap, schemaName);
        end
    end
end
