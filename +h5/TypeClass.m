classdef TypeClass < h5.interface.IsConstant
    %TYPECLASS A more general designator for a type.
    
    enumeration
        Reference('H5T_REFERENCE');
        String('H5T_STRING');
        Compound('H5T_COMPOUND');
    end
end

