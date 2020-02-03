classdef PrimitiveTypes
    %PRIMITIVETYPES enumeration of direct type mappings for matlab->h5 types
    % this enumeration is not exhaustive.
    % the enumeration names were chosen to match MATLAB primitive string names.
    
    methods (Static)
        function MatlabType = from_h5(H5Type)
            
            assert(isa(H5Type, 'h5.type.H5Types'),...
                'NWB:H5:PrimitiveTypes:InvalidType',...
                '`H5Type` must be a h5.type.H5Type');
            switch H5Type
                case {h5.PrimitiveTypes.ObjectRef,...
                        h5.PrimitiveTypes.DatasetRegionRef}
                    error('NWB:Matlab:PrimitiveTypes:NonPrimitive',...
                        ['Given type is not a primitive type.  Construct using a '...
                        'h5.Type instead.']);
                case h5.PrimitiveTypes.CString
                    MatlabType = matlab.PrimitiveTypes.char;
                case h5.PrimitiveTypes.Double
                    MatlabType = matlab.PrimitiveTypes.double;
                case h5.PrimitiveTypes.Single
                    MatlabType = matlab.PrimitiveTypes.single;
                case h5.PrimitiveTypes.I32
                    MatlabType = matlab.PrimitiveTypes.int32;
                case h5.PrimitiveTypes.I8
                    MatlabType = matlab.PrimitiveTypes.uint32;
                case h5.PrimitiveTypes.U8
                    MatlabType = matlab.PrimitiveTypes.uint8;
                case h5.PrimitiveTypes.I16
                    MatlabType = matlab.PrimitiveTypes.int16;
                case h5.PrimitiveTypes.U16
                    MatlabType = matlab.PrimitiveTypes.uint16;
                case h5.PrimitiveTypes.U32
                    MatlabType = matlab.PrimitiveTypes.uint32;
                case h5.PrimitiveTypes.I64
                    MatlabType = matlab.PrimitiveTypes.int64;
                case h5.PrimitiveTypes.U64
                    MatlabType = matlab.PrimitiveTypes.uint64;
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

