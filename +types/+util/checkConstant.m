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

    className = char(className);
    classNameParts = strsplit(className, '.');
    classReference = sprintf('<a href="matlab:doc %s">%s</a>', ...
        className, classNameParts{end});

    error('NWB:Type:ReadOnlyProperty', ...
        ['Unable to set the ''%s'' property of class ''%s'' because it ', ...
        'is read-only.'], char(name), classReference)
end
