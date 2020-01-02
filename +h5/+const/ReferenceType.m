classdef ReferenceType < h5.interface.IsConstant
    %REFERENCETYPE Constant indicating the type of Reference
    % Note that this is not a Type identifier but a separate enum used for raw
    % H5R_* function calls.
    
    enumeration
        Object('H5R_OBJECT');
        DatasetRegion('H5R_DATASET_REGION');
    end
end