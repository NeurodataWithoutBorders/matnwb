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
    if (isKey(spec, 'neurodata_type_inc') || isKey(spec, 'data_type_inc')) && ...
            ~(isKey(spec, 'neurodata_type_def') || isKey(spec, 'data_type_def'))
        % "inheritance" by inclusion
        if ~isKey(spec, 'dtype')
            spec('dtype') = 'any';
        end
        if ~isKey(spec, 'shape')
            spec('shape') = nan; %#ok<NASGU>
        end
    end
end
