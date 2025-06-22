function resolveInheritedFields(typeSpec, ancestorTypeSpecs)
% resolveInheritedFields - Resolve inherited fields from ancestor specification types.

    % Update type specifications based on ancestor types. In the schema
    % specification, types implicitly inherit keys from the corresponding
    % group, dataset, attribute, or link definitions of their ancestor types.
    % If a key is redefined in a subtype, only the overridden keys are updated.
    % To ensure that downstream generator classes use the inherited specification
    % values (instead of default ones), we loop through the type hierarchy and
    % fill in any missing key/value pairs from the ancestor specifications.

    primitiveTypes = enumeration('spec.enum.Primitives');
    
    for i = 1:length(ancestorTypeSpecs)
        ancestorType = ancestorTypeSpecs{i};

        for j = 1:numel(primitiveTypes)
            primitiveKey = primitiveTypes(j).Key;
            if isKey(typeSpec, primitiveKey) && isKey(ancestorType, primitiveKey)
                spec.internal.updateSpecFromParentSpec(...
                    typeSpec(primitiveKey), ancestorType(primitiveKey))
            end
        end
    end
end
