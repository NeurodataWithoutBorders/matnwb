classdef PrimitiveTypes < h5.interface.IsConstant
    %H5TYPES All available H5 types.  The enumeration values were chosen to match directly
    % with the expected strings for a preset h5 type.
    
    methods (Static)
        function PrimitiveType = from_matlab(matlabType)
            % note that we do need the data in order to determine type properly
            % this is due to the special case of character arrays and strings in MATLAB
            MSG_ID_CONTEXT = 'NWB:H5:PrimitiveTypes:FromMatlab:';
            
            assert(ischar(matlabType), [MSG_ID_CONTEXT 'InvalidArgument'],...
                'matlabType argument must be a character array of a valid matlab type.');
            
            allTypes = enumeration('h5.const.PrimitiveTypes');
            typeMatchMask = strcmp(matlabType, {allTypes.matlabType});
            assert(any(typeMatchMask), [MSG_ID_CONTEXT 'UnsupportedType'],...
                'data type `%s` is not a supported primitive type.', matlabType);
            
            PrimitiveType = allTypes(typeMatchMask);
        end
    end
    
    properties (SetAccess = immutable)
        matlabType;
    end
    
    methods % lifecycle (override)
        function obj = PrimitiveTypes(const_str, matlabType)
            obj = obj@h5.interface.IsConstant(const_str);
            obj.matlabType = matlabType;
        end
    end
    
    enumeration
        ObjectRef('H5T_STD_REF_OBJ', 'types.untyped.ObjectView');
        DatasetRegionRef('H5T_STD_REF_DSETREG', 'types.untyped.RegionView');
        Double('H5T_IEEE_F64LE', 'double');
        Single('H5T_IEEE_F32LE', 'single');
        I8('H5T_STD_I8LE', 'int8');
        U8('H5T_STD_U8LE', 'uint8');
        I16('H5T_STD_I16LE', 'int16');
        U16('H5T_STD_U16LE', 'uint16');
        I32('H5T_STD_I32LE', 'int32');
        U32('H5T_STD_U32LE', 'uint32');
        I64('H5T_STD_I64LE', 'int64');
        U64('H5T_STD_U64LE', 'uint64');
        % NOTE: see h5.Type for special serialization cases like `char` and
        % `datetime` types.  the 'cell' indicator used here is primarily for reading
        % (deserialization) only.
        CString('H5T_C_S1', 'cell'); 
    end
end