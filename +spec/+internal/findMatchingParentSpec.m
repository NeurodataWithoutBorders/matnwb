function matchingParentSpec = findMatchingParentSpec(spec, parentSpecs)
% findMatchingParentSpec - Find a spec from a set of parent specs matching on name

    matchingParentSpec = [];

    if isKey(spec, 'name')
        specId = spec('name');
        
        for j = 1:numel(parentSpecs)
            parentSpec = parentSpecs{j};
            
            if isKey(parentSpec, 'name') && strcmp(parentSpec('name'), specId)
                matchingParentSpec = parentSpec;
                break
            end
        end
    end
end
