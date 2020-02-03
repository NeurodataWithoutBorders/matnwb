function NwbObj = h5ToType(H5Obj)
%H52TYPE Converts h5.* object with attributes
assert(isa(H5Obj, 'h5.interface.HasAttributes'),...
    'NWB:H5ToType:InvalidArgument',...
    'Cannot convert H5 Object.');
Attributes = H5Obj.get_attributes();
attributeNames = {Attributes.get_name()};
typeNameMask = strcmp(attributeName, 'neurodata_type_def')...
    | strcmp(attributeName, 'data_type_def');
namespaceMask = strcmp(attributeName, 'namespace');
parentNameMask = strcmp(attributeName, 'neurodata_type_inc')...
    | strcmp(attributeName, 'data_type_inc');

assert(any(typeNameMask) && any(namespaceMask), 'NWB:H5ToType:InvalidType',...
    'H5 Object is not Typed.');

typeName = attributeNames{find(typeNameMask, 1)};

parentName = '';
if any(parentNameMask)
    parentName = attributeNames{find(parentNameMask, 1)};
end

namespaceName = attributeNames{find(namespaceMask, 1)};

if isa(H5Obj, 'h5.interface.IsHdfData')
    Type = H5Obj.get_type();
    if Type.get_id() == h5.PrimitiveTypes.DatasetRegionRef
    else
    end
end

if isa(H5Obj, 'h5.interface.HasSubObjects')
end

end