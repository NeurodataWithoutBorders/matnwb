function result = isPropertyHidden(propertyInfo, className, namespace)
% isPropertyHidden - Determine if a property is hidden

    if isa(propertyInfo, 'file.Attribute') || isa(propertyInfo, 'file.Dataset') 
        if strcmp(namespace.name, 'hdmf_common') ...
            && strcmp(className, 'VectorData') ...
            && any(strcmp(propertyInfo.name, {'unit', 'sampling_rate', 'resolution'}))
            result = true;
        else
            result = false;
        end
    else
        result = false;
    end
end
