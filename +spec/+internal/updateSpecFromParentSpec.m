function updateSpecFromParentSpec(childSpecs, parentSpecs)
% updateSpecFromParentSpec - Updates child specifications from parent specifications.
%
% Syntax:
%   schemes.internal.updateSpecFromParentSpec(childSpecs, parentSpecs)
%
% Input Arguments:
%   childSpecs - Cell array of child specification objects.
%   parentSpecs - Cell array of parent specification objects.
%
% Output Arguments:
%   None. The function modifies child specifications in place.

    specTypes = enumeration('spec.enum.Primitives');
    specTypeKeys = {specTypes.Key};

    for iSpec = 1:numel(childSpecs)
        currentSpec = childSpecs{iSpec};
        
        matchingParentSpec = spec.internal.findMatchingParentSpec(...
            currentSpec, parentSpecs);
    
        if isempty(matchingParentSpec)
            continue
        end

        parentSpecKeys = matchingParentSpec.keys();
        for iKey = 1:numel(parentSpecKeys)
            currentKey = parentSpecKeys{iKey};
            if any(strcmp(currentKey, specTypeKeys))
                if isKey(currentSpec, currentKey)
                    % Recursively update contained specification types
                    spec.internal.updateSpecFromParentSpec(...
                        currentSpec(currentKey), ...
                        matchingParentSpec(currentKey))
                end
            elseif ~isKey(currentSpec, currentKey)
                currentSpec(currentKey) = matchingParentSpec(currentKey);
            end
        end
    end
end
