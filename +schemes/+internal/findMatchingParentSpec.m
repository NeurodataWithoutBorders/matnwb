function matchingParentSpec = findMatchingParentSpec(spec, parentSpecs)
% findMatchingParentSpec - Find a spec from a parent specification set
% matching on name or "neurodata_type_inc"

    % The order here is important. All base types (i.e., groups, datasets, 
    % attributes, and links) can have a name. However, for groups and datasets,
    % the name is optional — if omitted, the specification identifier will 
    % default to the `neurodata_type_inc` value instead.
    ID_KEYS = ["name", "neurodata_type_inc"];

    matchingParentSpec = [];
    hasIdKey = false;

    for i = 1:numel(ID_KEYS)
        idKey = ID_KEYS(i);

        if isKey(spec, idKey)
            hasIdKey = true;
            specId = spec(idKey);
            
            for j = 1:numel(parentSpecs)
                parentSpec = parentSpecs{j};
                
                if isKey(parentSpec, idKey) && strcmp(parentSpec(idKey), specId)
                    matchingParentSpec = parentSpec;
                    break
                end
            end
        end
    end

    assert(hasIdKey, ...
        'NWB:Specification:SpecKeyMissing', ...
        'Expected specification to have an identifier key.')
end
