function id = getBaseType(type)
% H5T_INTEGER
% H5T_FLOAT
% H5T_STRING
switch type
    case 'char'
        typename = 'H5T_C_S1';
    case 'double'
        typename = 'H5T_NATIVE_DOUBLE';
    case 'int64'
        typename = 'H5T_NATIVE_INT';
    case 'uint64'
        typename = 'H5T_NATIVE_UINT';
    otherwise
        error('call to io.getBaseType only accepts `char|double|int64|uint64` as argument.');
end
id = H5T.copy(typename);
end