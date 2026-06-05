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
    if isempty(propertyNames) && ~isNWBFileType(typeName)
        propertyNameCache(typeName) = propertyNames;
        return
    end

    if isempty(propertyNames)
        try
            propertyNames = schemes.internal.getEagerLoadPropsForClass(typeName);
        catch ME
            recoverableErrorIds = { ...
                'NWB:Namespace:CacheMissing', ...
                'NWB:Scheme:Namespace:NotFound' ...
                };
            if ~any(strcmp(ME.identifier, recoverableErrorIds))
                rethrow(ME)
            end
            propertyNames = {};
        end
    end

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

function tf = isNWBFileType(typeName)
    tf = strcmp(typeName, 'NwbFile') || endsWith(typeName, '.NWBFile');
end
