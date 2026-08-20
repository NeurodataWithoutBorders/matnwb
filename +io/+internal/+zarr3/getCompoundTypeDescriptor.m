function typeDescriptor = getCompoundTypeDescriptor(info, fieldSemantics)
% getCompoundTypeDescriptor - Type descriptor for a compound Zarr array.
%
% Builds the compound type descriptor struct expected by types.util.checkDtype
% and types.untyped.DataStub.dataType. Returns a scalar struct with one field
% per info.fields entry (same name, same order -- checkDtype's
% validateCompoundTypeDescriptor requires exact field order), whose value is
% either 'types.untyped.ObjectView', when fieldSemantics marks that field as
% "object" (see io.internal.zarr3.getCompoundFieldSemantics), or the field's
% MATLAB class name (info.fields(k).Info.matlabClass) otherwise, e.g. 'int32'.
%
% info is a zarr.internal.dtype_info struct for a "structured" dtype
% (info.zarrType == "structured").

    arguments
        info (1,1) struct
        fieldSemantics
    end

    typeDescriptor = struct();
    for k = 1:numel(info.fields)
        f = info.fields(k);
        name = char(f.Name);
        if isKey(fieldSemantics, name) && fieldSemantics(name) == "object"
            typeDescriptor.(name) = 'types.untyped.ObjectView';
        else
            typeDescriptor.(name) = char(f.Info.matlabClass);
        end
    end
end
