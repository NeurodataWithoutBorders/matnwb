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

    for iSpec = 1:numel(childSpecs)
        currentSpec = childSpecs{iSpec};
        
        matchingAncestorSpec = spec.internal.findMatchingAncestorSpec(...
            currentSpec, ancestorSpecs);
    
        if isempty(matchingAncestorSpec)
            continue
        end

        spec.internal.expandInheritedFields(currentSpec, matchingAncestorSpec)
    end
end
