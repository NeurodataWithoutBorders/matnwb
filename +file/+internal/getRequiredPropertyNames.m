function requiredPropertyNames = getRequiredPropertyNames(classprops)
% getRequiredPropertyNames - Get name of required properties from props info

    allProperties = keys(classprops);
    requiredPropertyNames = {};
    
    for iProp = 1:length(allProperties)

        propertyName = allProperties{iProp};
        prop = classprops(propertyName);
    
        isRequired = ischar(prop) || isa(prop, 'containers.Map') || isstruct(prop);
        isPropertyRequired = false;
        if isa(prop, 'file.interface.HasProps')
            isPropertyRequired = false(size(prop));
            for iSubProp = 1:length(prop)
                p = prop(iSubProp);
                isPropertyRequired(iSubProp) = p.required;
            end
        end
    
        if isRequired || all(isPropertyRequired)
            requiredPropertyNames = [requiredPropertyNames {propertyName}]; %#ok<AGROW>
        end
    end
end
