function expandInheritedFields(childSpec, ancestorSpec)
% expandInheritedFields - Include specification keys from an ancestor
% specification for keys that are missing in a child specification.

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
                % Update specifications for nested HDMF primitive types
                spec.internal.updateSpecFromAncestorSpec(...
                    childSpec(currentAncestorKey), ...
                    ancestorSpec(currentAncestorKey))
            end
        elseif any(strcmp(currentAncestorKey, ignoreKeys))
            continue % skip ignore keys
        elseif ~isKey(childSpec, currentAncestorKey)
            childSpec(currentAncestorKey) = ancestorSpec(currentAncestorKey);
        end
    end
end
