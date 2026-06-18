function value = checkConstant(name, expectedValue, value, className)
% checkConstant - Validate a property whose value is fixed by the schema.

    arguments
        name {mustBeTextScalar}
        expectedValue
        value
        className {mustBeTextScalar}
    end

    if isequal(value, expectedValue)
        % Return the canonical schema value, not just the equivalent input value.
        value = expectedValue;
        return
    end

    name = char(name);
    className = char(className);
    classNameParts = strsplit(className, '.');
    classReference = sprintf('<a href="matlab:doc %s">%s</a>', ...
        className, classNameParts{end});

    types.util.reportSchemaViolation('NWB:Type:ReadOnlyProperty', ...
        sprintf(['The schema requires the ''%s'' property of class ''%s'' ' ...
        'to be %s, but the value is %s.'], ...
        name, classReference, formatValue(expectedValue), formatValue(value)))
end

function str = formatValue(value)
    if ischar(value) || (isstring(value) && isscalar(value))
        str = sprintf('''%s''', char(value));
    elseif isnumeric(value) || islogical(value)
        str = mat2str(value);
    else
        str = sprintf('<%s>', class(value));
    end
end
