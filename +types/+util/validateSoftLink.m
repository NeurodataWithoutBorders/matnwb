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
    elseif iscell(value)
        value = cellfun(@validateScalar, value, 'UniformOutput', false);
    elseif numel(value) > 1
        value = arrayfun(@validateScalar, value);
    else
        value = validateScalar(value);
    end

    function v = validateScalar(v)
        if isa(v, 'types.untyped.SoftLink')
            if ~isempty(v.target)
                types.util.checkType(propertyName, targetType, v.target);
            elseif ~isempty(v.target_type)
                assert(isNameOfA(v.target_type, targetType), ...
                    'NWB:ValidateSoftLink:InvalidNeurodataType', ...
                    ['Expected value for property `%s` to be of type ', ...
                    '`%s`, but got `%s` instead.'], ...
                    propertyName, targetType, v.target_type)
            end
        else
            types.util.checkType(propertyName, targetType, v);
            v = types.untyped.SoftLink(v);  % Wrap after successful validation
        end
    end
end

function tf = isNameOfA(actualClassName, className)
% isNameOfA - Determine if input is the name of the specified class 
%             (or name of a subclass of the specified class)

    if strcmp(actualClassName, className)
        tf = true;
    else
        tf = isNameOfASubclass(actualClassName, className);
    end
end

function tf = isNameOfASubclass(actualClassName, className)
    tf = false;
    
    mc = meta.class.fromName(actualClassName);
    if isempty(mc); return; end

    for i = 1:numel(mc.SuperclassList)
        currentName = mc.SuperclassList(i).Name;
        tf = isNameOfA(currentName, className);
        if tf; return; end
    end
end
