function typeDescriptor = getCompoundTypeDescriptor(info, objectReferenceFields)
% getCompoundTypeDescriptor - Type descriptor for a compound Zarr array.
%
% Builds the compound type descriptor struct expected by types.util.checkDtype
% and types.untyped.DataStub.dataType. Returns a scalar struct with one field
% per info.fields entry (same name, same order -- checkDtype's
% validateCompoundTypeDescriptor requires exact field order), whose value is
% either 'types.untyped.ObjectView', when objectReferenceFields names that
% field (see io.internal.zarr3.getObjectReferenceFields), or the field's
% MATLAB class name (info.fields(k).Info.matlabClass) otherwise, e.g. 'int32'.
%
% info is a zarr.internal.dtype_info struct for a "structured" dtype
% (info.zarrType == "structured").

    arguments
        info (1,1) struct
        objectReferenceFields (1,:) string
    end

    typeDescriptor = struct();
    for iField = 1:numel(info.fields)
        fieldInfo = info.fields(iField);
        name = char(fieldInfo.Name);
        if ismember(name, objectReferenceFields)
            typeDescriptor.(name) = 'types.untyped.ObjectView';
        else
            typeDescriptor.(name) = char(fieldInfo.Info.matlabClass);
        end
    end
end
