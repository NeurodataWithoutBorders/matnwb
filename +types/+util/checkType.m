function checkType(propertyName, typeName, value)
% checkType - Validate that a value is of the specified neurodata type.
%
% Skips validation if the value is empty.

    if isempty(value)
        return  % Skip validation for empty values.
    end

    assert(matnwb.utility.isNeurodataType(typeName), ...
        'NWB:CheckType:UnknownNeurodataType', ...
        'Expected `%s` to be a recognized neurodata type.', typeName);

    if ~isa(value, typeName)
        error('NWB:CheckType:InvalidNeurodataType', ...
            'Expected value for property `%s` to be of type `%s`, but got `%s` instead.', ...
            propertyName, typeName, class(value));
    end
end
