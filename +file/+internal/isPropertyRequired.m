function result = isPropertyRequired(propInfo, fullPropertyName, allClassprops)
% isPropertyRequired - Determine if a property is required

    if ischar(propInfo) || isa(propInfo, 'containers.Map') || isstruct(propInfo)
        result = true;
    elseif isa(propInfo, 'file.interface.HasProps')
        isSubPropertyRequired = false(size(propInfo));
        for iSubProp = 1:length(propInfo)
            p = propInfo(iSubProp);
            isSubPropertyRequired(iSubProp) = p.required;
        end
        result = all(isSubPropertyRequired);
    elseif isa(propInfo, 'file.Attribute')
        if isempty(propInfo.dependent)
            result = propInfo.required;
        else
            result = resolveRequiredForDependentProp(propInfo, fullPropertyName, allClassprops);
        end
    elseif isa(propInfo, 'file.Link')
        result = propInfo.required;
    else
        result = false;
    end
end

function tf = resolveRequiredForDependentProp(propInfo, propertyName, allProps)
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
