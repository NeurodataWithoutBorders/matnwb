function expandInheritedFields(childSpec, ancestorSpec)
    
    primitiveTypes = enumeration('spec.enum.Primitives');
    primitiveTypeKeys = {primitiveTypes.Key};

    ignoreKeys = { ...
        'neurodata_type_def', ...
        'data_type_def', ...
        'neurodata_type_inc', ...
        'data_type_inc'};

    ancestorSpecKeys = ancestorSpec.keys();
    for iKey = 1:numel(ancestorSpecKeys)
        currentAncestorKey = ancestorSpecKeys{iKey};
        if any(strcmp(currentAncestorKey, primitiveTypeKeys))
            if isKey(childSpec, currentAncestorKey)
                % Update nested specification primitives
                spec.internal.updateSpecFromAncestorSpec(...
                    childSpec(currentAncestorKey), ...
                    ancestorSpec(currentAncestorKey))
            end
        elseif any(strcmp(currentAncestorKey, ignoreKeys))
            continue
        elseif ~isKey(childSpec, currentAncestorKey)
            childSpec(currentAncestorKey) = ancestorSpec(currentAncestorKey);
        end
    end
end
