function updateSpecFromAncestorSpec(childSpecs, ancestorSpecs)
% updateSpecFromAncestorSpec - Updates child specifications from ancestor specifications.
%
% Syntax:
%   spec.internal.updateSpecFromAncestorSpec(childSpecs, ancestorSpecs)
%
% Input Arguments:
%   childSpecs - Cell array of child specification containers.Map objects.
%   ancestorSpecs - Cell array of ancestor specification containers.Map objects.
%
% Output Arguments:
%   None. The function modifies child specifications in place.

    primitiveTypes = enumeration('spec.enum.Primitives');
    primitiveTypeKeys = {primitiveTypes.Key};

    for iSpec = 1:numel(childSpecs)
        currentSpec = childSpecs{iSpec};
        
        matchingAncestorSpec = spec.internal.findMatchingAncestorSpec(...
            currentSpec, ancestorSpecs);
    
        if isempty(matchingAncestorSpec)
            continue
        end

        ancestorSpecKeys = matchingAncestorSpec.keys();
        for iKey = 1:numel(ancestorSpecKeys)
            currentAncestorKey = ancestorSpecKeys{iKey};
            if any(strcmp(currentAncestorKey, primitiveTypeKeys))
                if isKey(currentSpec, currentAncestorKey)
                    % Recursively update nested specification primitives
                    spec.internal.updateSpecFromAncestorSpec(...
                        currentSpec(currentAncestorKey), ...
                        matchingAncestorSpec(currentAncestorKey))
                end
            elseif ~isKey(currentSpec, currentAncestorKey)
                currentSpec(currentAncestorKey) = matchingAncestorSpec(currentAncestorKey);
            end
        end
    end
end
