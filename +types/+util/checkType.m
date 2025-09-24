function checkType(propertyName, expectedType, value)
% checkType - Validate that a value is of the specified neurodata type.
%
% Skips validation if the value is empty.

    if isempty(value)
        return  % Skip validation for empty values.
    end

    if isa(value, 'types.untyped.SoftLink')
        % Softlinks cannot be validated at this level.
        return;
    end

    assert(matnwb.utility.isNeurodataType(expectedType), ...
        'NWB:CheckType:UnknownNeurodataType', ...
        'Expected `%s` to be a recognized neurodata type.', expectedType);

    if isWrapped(value, expectedType)
        value = unwrapValue(value);
    end

    if ~isa(value, expectedType)
        error('NWB:CheckType:InvalidNeurodataType', ...
            'Expected value for property `%s` to be of type `%s`, but got `%s` instead.', ...
            propertyName, expectedType, class(value));
    end
end
