function parentTypeNames = listNwbTypeHierarchy(nwbTypeName)
% listNwbTypeHierarchy - List the NWB type hierarchy for an NWB type
    arguments
        nwbTypeName (1,1) string
    end

    parentTypeNames = string.empty;  % Initialize an empty cell array
    currentType = nwbTypeName; % Start with the specific type

    while ~strcmp(currentType, 'types.untyped.MetaClass')
        parentTypeNames(end+1) = currentType; %#ok<AGROW>
        
        % Use MetaClass information to get the parent type
        metaClass = meta.class.fromName(currentType);
        if isempty(metaClass.SuperclassList)
            break; % Reached the base type
        end
        % NWB parent type should always be the first superclass in the list
        currentType = metaClass.SuperclassList(1).Name;
    end
end
