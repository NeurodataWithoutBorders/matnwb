function value = validateReferenceType(propertyName, value, targetType, referenceType)
% validateReferenceType - Validates a value against a target type and wraps it in 
% the reference type if it is not already wrapped. 
% 
% Behavior:
% 1) If the value is a ObjectView or RegionView, validates its 'target' property.
% 2) Otherwise, validates the value against the expected target type.
%    If validation passes, the value is wrapped in a ObjectView/RegionView.
% Note: 
%   For arrays, applies validation element-wise.

    arguments
        propertyName (1,1) string
        value
        targetType (1,1) string
        referenceType (1,1) string {mustBeMember(referenceType, ...
            ["types.untyped.ObjectView", "types.untyped.RegionView"])}
    end

    if isempty(value)
        % Skip validation if value is empty, but ensure value is empty
        % double (i.e a "null" value).
        value = [];
    elseif iscell(value)
        value = cellfun(@validateScalar, value, 'UniformOutput', false);
    elseif numel(value) > 1
        value = arrayfun(@validateScalar, value);
    else
        value = validateScalar(value);
    end

    function result = validateScalar(v)
        if isa(v, referenceType)
            if ~isempty(v.target)
                types.util.checkType(propertyName, targetType, v.target);
            end
            result = v;
        else
            types.util.checkType(propertyName, targetType, v);
            result = feval(referenceType, v);
        end
    end
end
