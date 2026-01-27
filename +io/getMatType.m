function type = getMatType(tid)
%GETMATTYPE Given HDF5 type ID, returns string indicating probable MATLAB type.
if H5T.equal(tid, 'H5T_IEEE_F64LE')
    type = 'double';
elseif H5T.equal(tid, 'H5T_IEEE_F32LE')
    type = 'single';
elseif H5T.equal(tid, 'H5T_STD_U8LE')
    type = 'uint8';
elseif H5T.equal(tid, 'H5T_STD_I8LE')
    type = 'int8';
elseif H5T.equal(tid, 'H5T_STD_U16LE')
    type = 'uint16';
elseif H5T.equal(tid, 'H5T_STD_I16LE')
    type = 'int16';
elseif H5T.equal(tid, 'H5T_STD_U32LE')
    type = 'uint32';
elseif H5T.equal(tid, 'H5T_STD_I32LE')
    type = 'int32';
elseif H5T.equal(tid, 'H5T_STD_U64LE')
    type = 'uint64';
elseif H5T.equal(tid, 'H5T_STD_I64LE')
    type = 'int64';
elseif H5T.equal(tid, io.getBaseType('char'))
    type = 'char';
elseif H5T.equal(tid, 'H5T_STD_REF_OBJ')
    type = 'types.untyped.ObjectView';
elseif H5T.equal(tid, 'H5T_STD_REF_DSETREG')
    type = 'types.untyped.RegionView';
elseif H5T.get_class(tid) == H5ML.get_constant_value('H5T_ENUM')
    if io.isBool(tid)
        type = 'logical';
    else
        type = 'cell';
    end
elseif H5ML.get_constant_value('H5T_COMPOUND') == H5T.get_class(tid)
    type = extractCompoundTypeDescriptor(tid);
else
    if isa(tid, 'H5ML.id')
        identifier = tid.identifier;
        identifierFormat = '%d';
    else
        identifier = char(tid);
        identifierFormat = '%s';
    end
    error('NWB:IO:GetMatlabType:UnknownTypeID',...
        ['Unknown type id encountered (' identifierFormat ').'], ...
        identifier);
end
end

function typeDescriptor = extractCompoundTypeDescriptor(typeId)
%EXTRACTCOMPOUNDTYPEDESCRIPTOR Extract type descriptor from HDF5 compound type
%   typeDescriptor = extractCompoundTypeDescriptor(typeId) creates a
%   struct where each field name corresponds to a compound member and
%   the value is the MATLAB type string for that member.
    
    typeDescriptor = struct();
    numMembers = H5T.get_nmembers(typeId);
    
    for iMember = 0:(numMembers-1)
        memberName = H5T.get_member_name(typeId, iMember);
        memberTypeId = H5T.get_member_type(typeId, iMember);

        % Recursively get MATLAB type for this member
        % This handles nested compound types automatically
        memberType = io.getMatType(memberTypeId);
        
        H5T.close(memberTypeId);
        
        % Build type descriptor: typeDescriptor.fieldName = type
        typeDescriptor.(memberName) = memberType;
    end
end
