function result = isPropertyReadonly(propertyInfo)
% isPropertyReadonly - Determine if a property is read-only
    if isa(propertyInfo, 'file.Attribute') || isa(propertyInfo, 'file.Dataset') 
        result = propertyInfo.readonly;
    else
        result = false;
    end
end
