function typeDescriptor = getCompoundTypeDescriptor(info, objectReferenceFields)
% getCompoundTypeDescriptor - Type descriptor for a compound Zarr array.
%
% Builds the compound type descriptor struct expected by types.util.checkDtype
% and types.untyped.DataStub.dataType. Returns a scalar struct with one field
% per info.fields entry (same name, same order -- checkDtype's
% validateCompoundTypeDescriptor requires exact field order), whose value is
% either 'types.untyped.ObjectView', when objectReferenceFields names that
% field (see io.internal.zarr3.getObjectReferenceFields), or the field's
% MATLAB class name otherwise, e.g. 'int32' -- with text reported as 'char'
% (see matlabClassName below).
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
            typeDescriptor.(name) = matlabClassName(fieldInfo.Info.matlabClass);
        end
    end
end

function className = matlabClassName(matlabClass)
% matlabClassName - Field class, named the way the HDF5 backend names it.
%
% zarr-matlab represents both Zarr text types -- "string" and
% "fixed_length_utf32" -- as a MATLAB string, but the HDF5 backend reports
% H5T_STRING as char (io.internal.h5.datatype.datatypeInfoToMatlabType) and
% the generated type classes declare text compound fields as 'char'.
% Reporting char keeps a compound dataset's declared type independent of the
% backend that wrote it, which types.util.checkDtype relies on: its
% validateCompoundTypeDescriptor compares descriptor entries by name.
% io.backend.zarr3.Zarr3LazyArray converts the values to match on read.

    if string(matlabClass) == "string"
        className = 'char';
    else
        className = char(matlabClass);
    end
end
