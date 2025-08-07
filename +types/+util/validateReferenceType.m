function value = validateReferenceType(propertyName, value, targetType, referenceType)
% validateReferenceType - Validate and conditionally wrap a value in an ObjectView/RegionView.
%
% Behavior:
% 1) If the value is a ObjectView or RegionView, validates its 'target' property.
% 2) Otherwise, validates the value against the expected target type.
%    If validation passes, the value is wrapped in a ObjectView/RegionView.

    if isempty(value)
        % Skip validation if value is empty, but ensure value is empty
        % double (i.e a "null" value).
        return
    end

    if isa(value, referenceType)
        if ~isempty(value.target)
            types.util.checkType(propertyName, targetType, value.target);
        end
    else
        types.util.checkType(propertyName, targetType, value);
        value = feval(referenceType, value);  % Wrap after successful validation
    end
end
