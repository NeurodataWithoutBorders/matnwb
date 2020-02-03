classdef LinkType < h5.interface.IsConstant
    %LINKTYPE Link-specific designator for its type
    
    enumeration
        External('H5L_TYPE_EXTERNAL');
        Soft('H5L_TYPE_SOFT');
    end
end

