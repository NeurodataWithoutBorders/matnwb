function [previousTarget, cleanup] = validationTarget(newTarget, options)
% validationTarget - Get or set the current schema-validation target.
%
%   The new target can be provided either as a scalar struct with TypeName
%   and Path fields, or as name-value pairs (TypeName=..., Path=...).
%   The two forms cannot be combined.
%
%   [~, cleanup] = validationTarget(newTarget) additionally returns an onCleanup
%   handle that restores the prior target when it goes out of scope.
%   cleanup must be assigned to a named variable — if ignored, it fires
%   immediately and the state change is immediately undone.

    arguments
        newTarget struct = struct.empty % Struct with fields TypeName and Path
        options.TypeName (1,1) string
        options.Path (1,1) string
    end

    persistent activeTarget

    if isempty(activeTarget)
        activeTarget = [];
    end

    previousTarget = activeTarget;

    if ~isempty(newTarget) || ~isempty(fieldnames(options))
        assert(isempty(newTarget) || isempty(fieldnames(options)), ...
            'NWB:Validation:InvalidValidationTarget', ...
            'Specify target as a struct or as name-value pairs, not both.')
        if isempty(newTarget)
            newTarget = options;
        end
        validateTarget(newTarget)
        activeTarget = newTarget;
    end

    if nargout > 1
        cleanup = onCleanup(@() ...
            matnwb.common.validation.internal.validationTarget(previousTarget));
    end
end

function validateTarget(target)
    if isempty(target); return; end

    assert(isstruct(target) && isscalar(target), ...
        'NWB:Validation:InvalidValidationTarget', ...
        'Validation target must be a scalar struct.')
    assert(isfield(target, 'TypeName') && isfield(target, 'Path'), ...
        'NWB:Validation:InvalidValidationTarget', ...
        'Validation target must have TypeName and Path fields.')
    assert(isTextScalar(target.TypeName) && isTextScalar(target.Path), ...
        'NWB:Validation:InvalidValidationTarget', ...
        'Validation target TypeName and Path fields must be text scalars.')
end

function tf = isTextScalar(value)
    tf = ischar(value) || (isstring(value) && isscalar(value));
end
