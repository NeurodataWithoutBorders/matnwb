classdef PrimitiveTypes < h5.interface.IsConstant
    %H5TYPES All available H5 types.  The enumeration values were chosen to match directly
    % with the expected strings for a preset h5 type.
    
    methods (Static)
        function H5Type = from_matlab(MatlabType)
            assert(isa(MatlabType, 'matlab.PrimitiveTypes'),...
                'NWB:H5:PrimitiveTypes:InvalidType',...
                '`PrimitiveType` must be a matlab.PrimitiveTypes');
            
            switch MatlabType
                case matlab.PrimitiveTypes.char
                    H5Type = h5.PrimitiveTypes.CString;
                case matlab.PrimitiveTypes.double
                    H5Type = h5.PrimitiveTypes.Double;
                case matlab.PrimitiveTypes.single
                    H5Type = h5.PrimitiveTypes.Single;
                case {matlab.PrimitiveTypes.logical, matlab.PrimitiveTypes.uint32}
                    H5Type = h5.PrimitiveTypes.I32;
                case matlab.PrimitiveTypes.int8
                    H5Type = h5.PrimitiveTypes.I8;
                case matlab.PrimitiveTypes.uint8
                    H5Type = h5.PrimitiveTypes.U8;
                case matlab.PrimitiveTypes.int16
                    H5Type = h5.PrimitiveTypes.I16;
                case matlab.PrimitiveTypes.int32
                    H5Type = h5.PrimitiveTypes.I32;
                case matlab.PrimitiveTypes.int64
                     H5Type = h5.PrimitiveTypes.I64;
                case matlab.PrimitiveTypes.uint64
                     H5Type = h5.PrimitiveTypes.U64;
            end
        end
    end
    
    enumeration
        ObjectRef('H5T_STD_REF_OBJ');
        DatasetRegionRef('H5T_STD_REF_DSETREG');
        Double('H5T_IEEE_F64LE');
        Single('H5T_IEEE_F32LE');
        I8('H5T_STD_I8LE');
        U8('H5T_STD_U8LE');
        I16('H5T_STD_I16LE');
        U16('H5T_STD_U16LE');
        I32('H5T_STD_I32LE');
        U32('H5T_STD_U32LE');
        I64('H5T_STD_I64LE');
        U64('H5T_STD_U64LE');
        CString('H5T_C_S1');
    end
end

