function updateSpecFromAncestorSpec(childSpecs, ancestorSpecs)
% updateSpecFromAncestorSpec - Updates child specifications from ancestor specifications.
%
% Syntax:
%   spec.internal.updateSpecFromAncestorSpec(childSpecs, ancestorSpecs)
%
% Input Arguments:
%   childSpecs - Cell array of child specification objects.
%   ancestorSpecs - Cell array of ancestor specification objects.
%
% Output Arguments:
%   None. The function modifies child specifications in place.

    specTypes = enumeration('spec.enum.Primitives');
    specTypeKeys = {specTypes.Key};

    for iSpec = 1:numel(childSpecs)
        currentSpec = childSpecs{iSpec};
        
        matchingParentSpec = spec.internal.findMatchingAncestorSpec(...
            currentSpec, ancestorSpecs);
    
        if isempty(matchingParentSpec)
            continue
        end

        parentSpecKeys = matchingParentSpec.keys();
        for iKey = 1:numel(parentSpecKeys)
            currentKey = parentSpecKeys{iKey};
            if any(strcmp(currentKey, specTypeKeys))
                if isKey(currentSpec, currentKey)
                    % Recursively update contained specification types
                    spec.internal.updateSpecFromAncestorSpec(...
                        currentSpec(currentKey), ...
                        matchingParentSpec(currentKey))
                end
            elseif ~isKey(currentSpec, currentKey)
                currentSpec(currentKey) = matchingParentSpec(currentKey);
            end
        end
    end
end
