classdef PrimitiveTypes < h5.interface.IsConstant
    %H5TYPES All available H5 types.  The enumeration values were chosen to match directly
    % with the expected strings for a preset h5 type.
    
    methods (Static)
        function H5Type = from_matlab(data)
            % note that we do need the data in order to determine type properly
            % this is due to the special case of character arrays and strings in MATLAB
            import h5.const.PrimitiveTypes;
            
            ERR_MSG_STUB = 'NWB:H5:PrimitiveTypes:';
            switch class(data)
                case 'cell'
                    assert(iscellstr(data),...
                        [ERR_MSG_STUB 'GeneralCellNotSupported'],...
                        ['Cells in MATLAB are expected to be a cell array of'...
                        'character arrays.  Generic Cell arrays are not supported.']);
                    H5Type = PrimitiveTypes.CString;
                case {'char', 'datetime'}
                    H5Type = PrimitiveTypes.CString;
                case 'double'
                    H5Type = PrimitiveTypes.Double;
                case 'single'
                    H5Type = PrimitiveTypes.Single;
                case {'logical', 'int32'}
                    H5Type = PrimitiveTypes.I32;
                case 'int8'
                    H5Type = PrimitiveTypes.I8;
                case 'uint8'
                    H5Type = PrimitiveTypes.U8;
                case 'int16'
                    H5Type = PrimitiveTypes.I16;
                case 'uint16'
                    H5Type = PrimitiveTypes.U16;
                case 'uint32'
                    H5Type = PrimitiveTypes.U32;
                case 'int64'
                     H5Type = PrimitiveTypes.I64;
                case 'uint64'
                     H5Type = PrimitiveTypes.U64;
                otherwise
                    error([ERR_MSG_STUB 'InvalidType'],...
                        'Type `%s` is not a supported Matlab Type for H5.', data);
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

