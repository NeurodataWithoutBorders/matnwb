function propertyNames = getEagerLoadPropertyNames(typeName)
% getEagerLoadPropertyNames - Get eager-load policy for a generated type.

    arguments
        typeName (1,:) char
    end

    persistent propertyNameCache
    if isempty(propertyNameCache)
        propertyNameCache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end

    if isKey(propertyNameCache, typeName)
        propertyNames = propertyNameCache(typeName);
        return
    end

    propertyNames = getGeneratedEagerLoadPropertyNames(typeName);
    propertyNameCache(typeName) = propertyNames;
end

function propertyNames = getGeneratedEagerLoadPropertyNames(typeName)
    propertyNames = {};

    metaClass = meta.class.fromName(typeName);
    if isempty(metaClass)
        return
    end

    methodNames = string({metaClass.MethodList.Name});
    if ~any(methodNames == "getEagerLoadProperties")
        return
    end

    propertyNames = feval([typeName '.getEagerLoadProperties']);
end
