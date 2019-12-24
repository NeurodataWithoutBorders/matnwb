classdef DefaultType < h5.Type
    %DEFAULTTYPE h5.Type generator.
    
    enumeration
        ObjectReference('H5T_STD_REF_OBJ');
        DatasetRegionReference('H5T_STD_REF_DSETREG');
        Double('H5T_IEEE_F64LE');
        Single('H5T_IEEE_F32LE');
        Bool('H5T_STD_I32LE');
        I8('H5T_STD_I8LE');
        U8('H5T_STD_U8LE');
        I16('H5T_STD_I16LE');
        U16('H5T_STD_U16LE');
        I32('H5T_STD_I32LE');
        U32('H5T_STD_U32LE');
        I64('H5T_STD_I64LE');
        U64('H5T_STD_U64LE');
        String('H5T_C_S1');
    end
end

