function mustBeDynamicTable(value)
% mustBeDynamicTable - Validate that value is a DynamicTable object
    
    import matnwb.common.validation.internal.mustBeCompatibleType

    try
        mustBeCompatibleType(value, "DynamicTable")
    catch exception
        error(...
            'NWB:validators:mustBeDynamicTable', ...
            exception.message);
    end
end
