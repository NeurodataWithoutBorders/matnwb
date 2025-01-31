function mustBeH5File(value)
    arguments
        value {mustBeFile}
    end

    VALID_FILE_ENDING = ["h5", "nwb"];
    validExtensions = "." + VALID_FILE_ENDING;

    hasH5Extension = endsWith(value, validExtensions, 'IgnoreCase', true);    
    
    if ~hasH5Extension
        exception = MException(...
            'NWB:validators:mustBeH5File', ...
            'Expected file "%s" to have .h5 or .nwb file extension', value);
        throwAsCaller(exception)
    end
end
