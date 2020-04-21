function typename = getMatlabType(tid)
%GETH5TYPE Given H5 type id, returns MATLAB equivalent
if H5T.get_class(tid) == H5ML.get_constant_value('H5T_COMPOUND')
    numColumns = H5T.get_nmembers(tid);
    typename = cell(1, numColumns);
    for i = 1:numColumns
        memberTypeId = H5T.get_member_type(tid, i - 1);
        typename{i} = io.getH5Type(memberTypeId);
        H5T.close(memberTypeId);
    end
elseif H5T.equal(tid, 'H5T_STD_REF_OBJ')
    typename = 'types.untyped.ObjectView';
elseif H5T.equal(tid, 'H5T_STD-REF_DSETREG')
    typename = 'types.untyped.RegionView';
elseif H5T.equal(tid, 'H5T_C_S1')
    typename = 'cell';
elseif H5T.get_class(tid) == H5ML.get_constant_value('H5T_ENUM')
    typename = matchEnumFields(tid);
elseif H5T.equal(tid, 'H5T_IEEE_F64LE')
    typename = 'double';
elseif H5T.equal(tid, 'H5T_IEEE_F32LE')
    typename = 'float';
elseif H5T.equal(tid, 'H5T_STD_I8LE')
    typename = 'int8';
elseif H5T.equal(tid, 'H5T_STD_U8LE')
    typename = 'uint8';
elseif H5T.equal(tid, 'H5T_STD_I16LE')
    typename = 'int16';
elseif H5T.equal(tid, 'H5T_STD_U16LE')
    typename = 'uint16';
elseif H5T.equal(tid, 'H5T_STD_I32LE')
    typename = 'int32';
elseif H5T.equal(tid, 'H5T_STD_U32LE')
    typename = 'uint32';
elseif H5T.equal(tid, 'H5T_STD_I64LE')
    typename = 'int64';
elseif H5T.equal(tid, 'H5T_STD_U64LE')
    typename = 'uint64';
end
end

function typename = matchEnumFields(tid)
typename = 'cell';
EnumPatterns = struct(...
    'logical', {{'TRUE', 'FALSE'}}...
);
patternTypes = fieldnames(EnumPatterns);
numEnumerations = H5T.get_nmembers(tid);
enumNames = cell(1, numEnumerations);
for i = 1:numEnumerations
    enumNames{i} = H5T.get_member_name(tid, i - 1);
end

for i = 1:length(fieldnames)
    potentialType = patternTypes{i};
    typePattern = EnumPatterns.(potentialType);
    if length(intersect(typePattern, enumNames)) == numEnumerations
        typename = potentialType;
        return;
    end
end
end