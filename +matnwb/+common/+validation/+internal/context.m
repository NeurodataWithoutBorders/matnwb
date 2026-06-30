function [previousContext, cleanup] = context(newContext)
% context - Get or set the process-local schema validation context.
%
%   [~, cleanup] = context(newContext) additionally returns an onCleanup
%   handle that restores the prior context when it goes out of scope.
%   cleanup must be assigned to a named variable — if ignored, it fires
%   immediately and the state change is immediately undone.

    arguments
        newContext matnwb.common.validation.internal.ValidationContext = ...
            matnwb.common.validation.internal.ValidationContext.empty
    end

    persistent activeContext

    if isempty(activeContext)
        activeContext = matnwb.common.validation.internal.ValidationContext.EDIT;
    end

    previousContext = activeContext;

    if ~isempty(newContext)
        assert(isscalar(newContext), ...
            'NWB:Validation:InvalidContext', ...
            'Validation context must be scalar.')
        activeContext = newContext;
    end

    if nargout > 1
        cleanup = onCleanup(@() ...
            matnwb.common.validation.internal.context(previousContext));
    end
end
