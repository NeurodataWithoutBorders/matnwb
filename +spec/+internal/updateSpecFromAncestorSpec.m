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
        
        matchingAncestorSpec = spec.internal.findMatchingAncestorSpec(...
            currentSpec, ancestorSpecs);
    
        if isempty(matchingAncestorSpec)
            continue
        end

        ancestorSpecKeys = matchingAncestorSpec.keys();
        for iKey = 1:numel(ancestorSpecKeys)
            currentKey = ancestorSpecKeys{iKey};
            if any(strcmp(currentKey, specTypeKeys))
                if isKey(currentSpec, currentKey)
                    % Recursively update contained specification types
                    spec.internal.updateSpecFromAncestorSpec(...
                        currentSpec(currentKey), ...
                        matchingAncestorSpec(currentKey))
                end
            elseif ~isKey(currentSpec, currentKey)
                currentSpec(currentKey) = matchingAncestorSpec(currentKey);
            end
        end
    end
end
