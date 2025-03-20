function result = isPropertyRequired(prop, fullPropertyName, classprops)
% isPropertyRequired - Determine if a property is required

    if ischar(prop) || isa(prop, 'containers.Map') || isstruct(prop)
        result = true;
    
    elseif isa(prop, 'file.interface.HasProps')
        isSubPropertyRequired = false(size(prop));
        for iSubProp = 1:length(prop)
            p = prop(iSubProp);
            isSubPropertyRequired(iSubProp) = p.required;
        end
        result = all(isSubPropertyRequired);

    elseif isa(prop, 'file.Attribute')
        if isempty(prop.dependent)
            result = prop.required;
        else
            result = resolveRequiredForDependentProp(fullPropertyName, prop, classprops);
        end
    elseif isa(prop, 'file.Link')
        result = prop.required;
    else
        result = false;
    end
end

function tf = resolveRequiredForDependentProp(propertyName, propInfo, allProps)
% resolveRequiredForDependentProp - If a dependent property is required,
% whether it is required on object level also depends on whether it's parent 
% property is required.
    if ~propInfo.required 
        tf = false;
    else % Check if parent is required
        parentName = strrep(propertyName, ['_' propInfo.name], '');
        parentInfo = allProps(parentName);
        tf = parentInfo.required;
    end
end
