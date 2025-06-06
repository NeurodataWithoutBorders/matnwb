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
    H5T.set_cset(id, H5ML.get_constant_value('H5T_CSET_UTF8'))
elseif strcmp(type, 'double')
    id = 'H5T_IEEE_F64LE';
elseif strcmp(type, 'single')
    id = 'H5T_IEEE_F32LE';
elseif strcmp(type, 'logical')
    id = H5T.enum_create('H5T_STD_I8LE');
    H5T.enum_insert(id, 'FALSE', 0);
    H5T.enum_insert(id, 'TRUE', 1);
elseif startsWith(type, {'int' 'uint'})
    prefix = 'H5T_STD_';
    pattern = 'int%d';
    if type(1) == 'u'
        pattern = ['u' pattern];
    end
    suffix = sscanf(type, pattern);
    
    switch suffix
        case 8
            suffix = '8LE';
        case 16
            suffix = '16LE';
        case 32
            suffix = '32LE';
        case 64
            suffix = '64LE';
    end
    
    if type(1) == 'u'
        suffix = ['U' suffix];
    else
        suffix = ['I' suffix];
    end
    
    id = [prefix suffix];
else
    error('NWB:IO:UnsupportedBaseType', ...
        'Type `%s` is not a supported raw type', type);
end
end