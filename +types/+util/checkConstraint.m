function val = checkConstraint(pname, name, namedprops, constrained, val)
    if isempty(val)
        return;
    end

    names = fieldnames(namedprops);
    if any(strcmp(name, names))
        val = types.util.checkDtype([pname '.' name], namedprops.(name), val);
        return;
    end
    
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
