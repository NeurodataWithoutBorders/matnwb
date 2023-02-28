function checkConstraint(pname, name, namedprops, constrained, val)
    if isempty(val)
        return;
    end

    names = fieldnames(namedprops);
    if any(strcmp(name, names))
        types.util.checkDtype([pname '.' name], namedprops.(name), val);
        return;
    end
    
    for i=1:length(constrained)
        allowedType = constrained{i};
        try
            types.util.checkDtype([pname '.' name], allowedType, val);
            return;
        catch ME
            expectedErrorTypes = {...
                'NWB:CheckDType:InvalidType', ...
                'NWB:CheckDType:InvalidShape', ...
                'NWB:TypeCorrection:InvalidConversion'};
            if any(strcmp(ME.identifier, expectedErrorTypes))
                fprintf('Checking data type `%s` for object of class `%s`.\n  Threw with error: %s\n', ...
                    allowedType, class(val), ME.message);
            else
                rethrow(ME);
            end
        end
    end
    error('NWB:CheckConstraint:InvalidType',...
        'Property `%s.%s` should be one of type(s) {%s}. Found type "%s"',...
        pname, name, misc.cellPrettyPrint(constrained), class(val));
end