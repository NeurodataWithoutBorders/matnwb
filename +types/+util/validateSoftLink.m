function value = validateSoftLink(propertyName, value, targetType)
% validateSoftLink - Validate and conditionally wrap a value in a SoftLink.
%
% Behavior:
% 1) If the value is a SoftLink, validates its 'target' property.
% 2) Otherwise, validates the value against the expected target type.
%    If validation passes, the value is wrapped in a SoftLink.

    if isempty(value)
        % Skip validation if value is empty, but ensure value is empty
        % double (i.e a "null" value).
        return
    end

    if isa(value, 'types.untyped.SoftLink')
        if ~isempty(value.target)
            types.util.checkType(propertyName, targetType, value.target);
        end
    else
        types.util.checkType(propertyName, targetType, value);
        value = types.untyped.SoftLink(value);  % Wrap after successful validation
    end
end
