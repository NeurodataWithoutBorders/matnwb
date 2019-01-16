function id = getBaseType(type)
% we limit ourselves to the predefined native types and standard datatypes when applicable
% https://portal.hdfgroup.org/display/HDF5/Predefined+Datatypes
if strcmp(type, 'types.untyped.ObjectView')
    id = 'H5T_STD_REF_OBJ';
elseif strcmp(type, 'types.untyped.RegionView')
    id = 'H5T_STD_REF_DSETREG';
elseif any(strcmp(type, {'char' 'cell' 'datetime'}))
    %modify id to set the proper size
    id = H5T.copy('H5T_C_S1');
    H5T.set_size(id, 'H5T_VARIABLE');
elseif strcmp(type, 'double')
    id = 'H5T_NATIVE_DOUBLE';
elseif strcmp(type, 'single')
    id = 'H5T_NATIVE_FLOAT';
elseif strcmp(type, 'logical')
    id = 'H5T_NATIVE_HBOOL';
elseif startsWith(type, {'int' 'uint'})
    prefix = 'H5T_NATIVE_';
    pattern = 'int%d';
    if type(1) == 'u'
        pattern = ['u' pattern];
    end
    suffix = sscanf(type, pattern);
    
    switch suffix
        case 8
            suffix = 'CHAR';
        case 16
            suffix = 'SHORT';
        case 32
            suffix = 'LONG';
        case 64
            suffix = 'LLONG';
    end
    
    if type(1) == 'u'
        suffix = ['U' suffix];
    end
    
    id = [prefix suffix];
else
    error('Type `%s` is not a support raw type', type);
end
end