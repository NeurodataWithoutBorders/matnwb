classdef ObjectType < h5.interface.IsConstant
    %OBJECTTYPE H5O type enum
    
    enumeration
        Dataset('H5G_DATASET');
        Group('H5G_GROUP');
        Link('H5G_LINK');
    end
end

