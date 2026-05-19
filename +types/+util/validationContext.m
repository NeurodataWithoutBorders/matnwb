function previousContext = validationContext(newContext)
%VALIDATIONCONTEXT Track whether validation is strict or running during parsed reads.

    persistent currentContext

    if isempty(currentContext)
        currentContext = 'strict';
    end

    previousContext = currentContext;

    if nargin > 0
        newContext = validatestring(newContext, {'strict', 'read'});
        currentContext = newContext;
    end
end
