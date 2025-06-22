function matchingAncestorSpec = findMatchingAncestorSpec(spec, ancestorSpecs)
% findMatchingAncestorSpec - Find a spec from a set of ancestor specs matching on name

    matchingAncestorSpec = [];

    if isKey(spec, 'name')
        specId = spec('name');
        
        for j = 1:numel(ancestorSpecs)
            ancestorSpec = ancestorSpecs{j};
            
            if isKey(ancestorSpec, 'name') && strcmp(ancestorSpec('name'), specId)
                matchingAncestorSpec = ancestorSpec;
                break
            end
        end
    end
end
