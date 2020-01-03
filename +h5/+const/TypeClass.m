classdef TypeClass < h5.interface.IsConstant
    %TYPECLASS A more general designator for a type.
    
    enumeration
        Integer('H5T_INTEGER');
        Float('H5T_FLOAT');
        BitField('H5T_BITFIELD');
        Opaque('H5T_OPAQUE');
        Enum('H5T_ENUM');
        VariableLengthType('H5T_VLEN');
        Array('H5T_ARRAY');
        Reference('H5T_REFERENCE');
        String('H5T_STRING');
        Compound('H5T_COMPOUND');
        NoClass('H5T_NO_CLASS');
    end
end

