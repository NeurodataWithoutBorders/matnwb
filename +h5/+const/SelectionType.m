classdef SelectionType < h5.interface.IsConstant
    %SELECTIONTYPE Space Selection Type.  Only Hyperslabs is supported.
    
    enumeration
        Hyperslabs('H5S_SEL_HYPERSLABS');
    end
end

