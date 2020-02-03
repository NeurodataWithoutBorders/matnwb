classdef H5Types < h5.interface.IsConstant
    %H5TYPES All available H5 types.  The enumeration values were chosen to match directly
    % with the expected strings for a preset h5 type.
    
    methods (Static)
        function H5Type = from_primitive(PrimitiveType)
            import h5.type.PrimitiveTypes;
            import h5.type.H5Types;
            
            assert(isa(PrimitiveType, 'h5.type.PrimitiveTypes'),...
                'NWB:H5:H5Types:InvalidType',...
                '`PrimitiveType` must be a h5.type.PrimitiveTypes');
            
            switch PrimitiveType
                case PrimitiveTypes.char
                    H5Type = H5Types.CString;
                case PrimitiveTypes.double
                    H5Type = H5Types.Double;
                case PrimitiveTypes.single
                    H5Type = H5Types.Single;
                case {PrimitiveTypes.logical, PrimitiveTypes.uint32}
                    H5Type = H5Types.I32;
                case PrimitiveTypes.int8
                    H5Type = H5Types.I8;
                case PrimitiveTypes.uint8
                    H5Type = H5Types.U8;
                case PrimitiveTypes.int16
                    H5Type = H5Types.I16;
                case PrimitiveTypes.int32
                    H5Type = H5Types.I32;
                case PrimitiveTypes.int64
                     H5Type = H5Types.I64;
                case PrimitiveTypes.uint64
                     H5Type = H5Types.U64;
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

