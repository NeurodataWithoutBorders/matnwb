classdef IdTypes < h5.interface.IsConstant
    %IDENTIFIERS H5I enum
    
    enumeration
        File('H5I_FILE');
        Group('H5I_GROUP');
        Datatype('H5I_DATATYPE');
        Dataspace('H5I_DATASPACE');
        Dataset('H5I_DATASET');
        Attribute('H5I_ATTR');
        Invalid('H5I_BADID');
    end
end