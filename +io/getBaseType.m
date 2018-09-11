function id = getBaseType(type, data)
switch type
    case 'types.untyped.ObjectView'
        id = 'H5T_STD_REF_OBJ';
    case 'types.untyped.RegionView'
        id = 'H5T_STD_REF_DSETREG';
    case {'char' 'cell'}
        %modify id to set the proper size
        id = H5T.copy('H5T_C_S1');
        if iscellstr(data)
            %if data is a cell array of str, then return the maximum size
            %The data must now be converted to char array evenly padded to
            %this maximum size
            tsize = max(cellfun('length', data));
        else
            tsize = size(data, 2);
        end
        if tsize <= 0
            tsize = 'H5T_VARIABLE';
        end
        H5T.set_size(id, tsize);
    case 'double'
        id = 'H5T_NATIVE_DOUBLE';
    case 'int64'
        id = 'H5T_NATIVE_LLONG';
    case 'uint64'
        id = 'H5T_NATIVE_ULLONG';
    case 'int32'
        id = 'H5T_NATIVE_INT';
    case 'single'
        id = 'H5T_NATIVE_FLOAT';
    case 'logical'
        id = 'H5T_NATIVE_HBOOL';
    otherwise
        error('Type `%s` is not a support raw type', type);
end
end