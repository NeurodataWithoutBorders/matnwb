classdef SpaceType < h5.interface.IsConstant
    %SPACETYPE Available space type
    % These enumeration values coincide with H5S space types.
    
    enumeration
        Scalar('H5S_SCALAR');
        Simple('H5S_SIMPLE');
        Null('H5S_NULL');
    end
end

