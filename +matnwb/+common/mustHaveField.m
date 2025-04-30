function mustHaveField(s, fieldName)
% mustHaveField - Validate that structure has field(s) with given fieldname(s)
    arguments
        s struct
    end
    arguments (Repeating)
        fieldName (1,1) string
    end

    fieldName = string(fieldName);

    isMissingField = ~isfield(s, fieldName);
    assert(all(~isMissingField), ...
        'NWB:validators:MustHaveField', ...
        'Expected structure to have field(s):\n%s\n', ...
        strjoin("  " + fieldName(isMissingField), newline) )
end
