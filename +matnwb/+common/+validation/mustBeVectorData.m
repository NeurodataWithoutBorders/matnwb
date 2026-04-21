function mustBeVectorData(value)
% mustBeVectorData - Validate that value is a VectorData object
    
    import matnwb.common.validation.internal.mustBeCompatibleType

    try
        mustBeCompatibleType(value, "VectorData")
    catch exception
        error(...
            'NWB:validators:mustBeVectorData', ...
            exception.message);
    end
end
