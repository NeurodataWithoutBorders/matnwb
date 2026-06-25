function val = checkConstraint(pname, name, namedprops, constrained, val)
    if isempty(val)
        return;
    end

    names = fieldnames(namedprops);
    if any(strcmp(name, names))
        % Named properties have a single schema-defined dtype, so this can use
        % normal report-mode validation directly.
        val = types.util.checkDtype([pname '.' name], namedprops.(name), val);
        return;
    end
    
    % Constrained properties are unions: a value is valid if it matches any
    % allowed dtype. Each candidate must be checked in strict mode so a failed
    % candidate throws and the next one can be tried. Only after all candidates
    % fail do we report one context-sensitive schema violation for the property.
    for i=1:length(constrained)
        allowedType = constrained{i};
        try
            val = types.util.checkDtype( ...
                [pname '.' name], allowedType, val, Mode="strict");
            return;
        catch ME
            if ~isExpectedValidationError(ME)
                rethrow(ME);
            end
        end
    end
    matnwb.common.validation.reportSchemaViolation( ...
        'NWB:CheckConstraint:InvalidType', ...
        sprintf('Property `%s.%s` should be one of type(s) {%s}. Found type "%s"', ...
        pname, name, misc.cellPrettyPrint(constrained), class(val)));
end

function tf = isExpectedValidationError(exception)
    expectedPrefixes = "NWB:CheckDType:";
    expectedIds = [ ...
        "NWB:CheckDataType:InvalidConversion", ...
        "NWB:TypeCorrection:InvalidConversion", ...
        "NWB:TypeCorrection:PrecisionLossDetected"];

    tf = startsWith(string(exception.identifier), expectedPrefixes) ...
        || any(strcmp(exception.identifier, expectedIds));
end
