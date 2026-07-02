function mapping = getSchemaPropertyNameMapping(target)
% getSchemaPropertyNameMapping - Read a type's SchemaPropertyNameMapping constant
%
% mapping = getSchemaPropertyNameMapping(target) returns the struct that maps
% property identifiers to their schema names for reserved-keyword fields (e.g.
% struct('events_', 'events')), or [] when the class declares no such mapping.
%
% target may be a neurodata type instance or a fully qualified class name
% (char/string). Using an instance avoids a metaclass lookup.
    if ischar(target) || isstring(target)
        mapping = getMappingByTypeName(char(target));
    else
        mapping = getMappingByInstance(target);
    end
end

function mapping = getMappingByInstance(obj)
    mapping = [];
    if isprop(obj, 'SchemaPropertyNameMapping')
        mapping = obj.SchemaPropertyNameMapping;
    end
end

function mapping = getMappingByTypeName(typeName)
    % Read the (inherited or own) constant without instantiating the class.
    % meta.class objects are cached and invalidated by MATLAB on class
    % redefinition, so no additional caching is needed here.
    mapping = [];
    metaClass = meta.class.fromName(typeName);
    if isempty(metaClass)
        return
    end
    isMappingProperty = strcmp({metaClass.PropertyList.Name}, 'SchemaPropertyNameMapping');
    if any(isMappingProperty)
        mapping = metaClass.PropertyList(isMappingProperty).DefaultValue;
    end
end
