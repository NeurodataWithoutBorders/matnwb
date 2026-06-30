function previousContext = context(newContext)
% context - Get or set the process-local schema validation context.

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
end
