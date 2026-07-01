function reportSchemaViolation(errorId, message, causes, options)
% reportSchemaViolation - Raise a schema-validation issue as an error or warning.
%   By default, schema violations are errors. During read/deserialization,
%   they are warnings so existing files remain readable. Callers can request
%   warning behavior for specific backwards-compatible validators, but write
%   validation always errors.
%
%   Callers pass a fully formed, context-neutral message describing the
%   violation. Optional CAUSES (an array of MException objects) are attached
%   as causes when erroring, and their messages are appended to the text when
%   warning, because warnings cannot carry structured causes.

    arguments
        errorId (1,1) string
        message (1,1) string
        causes (1,:) MException = MException.empty(1, 0)
        options.WarnInsteadOfError (1,1) logical = false
    end

    import matnwb.common.validation.internal.ValidationContext

    validationContext = matnwb.common.validation.internal.context();
    isReadContext = validationContext == ValidationContext.READ;
    isWriteContext = validationContext == ValidationContext.WRITE;

    if ~isWriteContext && (isReadContext || options.WarnInsteadOfError)
        lenientGuidance = ['The non-conforming value is kept. If you maintain ' ...
            'this data, consider correcting it before export.'];

        fullMessage = message;
        for iCause = 1:numel(causes)
            fullMessage = fullMessage + " " + string(causes(iCause).message);
        end
        target = matnwb.common.validation.internal.validationTarget();
        if isReadContext && ~isempty(target)
            targetMessage = sprintf( ...
                'While reading object of type "%s" at file location "%s".', ...
                target.TypeName, target.Path);
            fullMessage = fullMessage + " " + targetMessage;
        end
        fullMessage = fullMessage + " " + lenientGuidance;

        warning(errorId, '%s', fullMessage)
    else
        exception = MException(errorId, '%s', message);
        for iCause = 1:numel(causes)
            exception = exception.addCause(causes(iCause));
        end
        throw(exception)
    end
end
