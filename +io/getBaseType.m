function id = getBaseType(type)
% H5T_INTEGER
% H5T_FLOAT
% H5T_STRING
switch type
    case 'char'
        classid = H5ML.get_constant_value('H5T_STRING');
        sz = 16;
    case 'double'
        classid = H5ML.get_constant_value('H5T_FLOAT');
        sz = 8;
    case {'int64' 'uint64'}
        classid = H5ML.get_constant_value('H5T_INTEGER');
        sz = 8;
    otherwise
        error('call to io.getBaseType only accepts `char|double|int64|uint64` as argument.');
end
id = H5T.create(classid, sz);
end