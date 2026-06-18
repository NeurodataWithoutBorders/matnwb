function propertyMap = eagerLoadProperties(typeName, propertyMap)
% eagerLoadProperties - Load DataStub values selected by a type read policy.

    arguments
        typeName (1,:) char
        propertyMap containers.Map
    end

    eagerLoadPropertyNames = io.internal.getEagerLoadPropertyNames(typeName);
    for iProperty = 1:numel(eagerLoadPropertyNames)
        propertyName = eagerLoadPropertyNames{iProperty};
        if ~isKey(propertyMap, propertyName)
            continue
        end

        propertyValue = propertyMap(propertyName);
        if isa(propertyValue, 'types.untyped.DataStub')
            propertyMap(propertyName) = propertyValue.load();
        end
    end
end
