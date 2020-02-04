classdef PrimitiveTypes
    %PRIMITIVETYPES enumeration of direct type mappings for matlab->h5 types
    % this enumeration is not exhaustive.
    % the enumeration names were chosen to match MATLAB primitive string names.
    
    methods (Static)
        function PrimitiveType = from_h5(H5Type)
            import h5.type.H5Types;
            import h5.type.PrimitiveTypes;
            
            assert(isa(H5Type, 'h5.type.H5Types'),...
                'NWB:H5:PrimitiveTypes:InvalidType',...
                '`H5Type` must be a h5.type.H5Type');
            switch H5Type
                case {H5Types.ObjectRef,...
                        H5Types.DatasetRegionRef}
                    error('NWB:H5:PrimitiveTypes:NonPrimitive',...
                        ['Given type is not a primitive type.  Construct using a '...
                        'h5.Type instead.']);
                case H5Types.CString
                    PrimitiveType = PrimitiveTypes.char;
                case H5Types.Double
                    PrimitiveType = PrimitiveTypes.double;
                case H5Types.Single
                    PrimitiveType = PrimitiveTypes.single;
                case H5Types.I32
                    PrimitiveType = PrimitiveTypes.int32;
                case H5Types.I8
                    PrimitiveType = PrimitiveTypes.uint32;
                case H5Types.U8
                    PrimitiveType = PrimitiveTypes.uint8;
                case H5Types.I16
                    PrimitiveType = PrimitiveTypes.int16;
                case H5Types.U16
                    PrimitiveType = PrimitiveTypes.uint16;
                case H5Types.U32
                    PrimitiveType = PrimitiveTypes.uint32;
                case H5Types.I64
                    PrimitiveType = PrimitiveTypes.int64;
                case H5Types.U64
                    PrimitiveType = PrimitiveTypes.uint64;
            end
        end
    end
    
    enumeration
        cell;
        datetime;
        char;
        double;
        single;
        logical;
        int8;
        uint8;
        int16;
        int32;
        uint32;
        int64;
        uint64;
    end
end

