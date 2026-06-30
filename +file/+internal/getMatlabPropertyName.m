function propertyName = getMatlabPropertyName(schemaName)
% getMatlabPropertyName - Map a schema field name to a valid MATLAB property name
%
% MATLAB forbids the classdef block keywords ("events", "methods",
% "properties", "enumeration") as property names, so a schema field with one
% of these names is given a trailing underscore (e.g. "events" -> "events_").
% All other names are returned unchanged. The on-disk/schema name is not
% affected by this mapping; MatNWB remaps the name on read and write (see the
% SchemaPropertyNameMapping constant emitted by file.fillClass).
    arguments
        schemaName (1,:) char
    end

    reservedKeywords = file.internal.reservedPropertyNames();
    if ismember(schemaName, reservedKeywords)
        propertyName = [schemaName '_'];
    else
        propertyName = schemaName;
    end
end
