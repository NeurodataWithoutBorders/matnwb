function reportSchemaViolation(errorId, message, causes)
% reportSchemaViolation - Raise a schema-validation issue as an error or warning.
%   In the default (strict) validation context the issue is raised as an
%   error. When parsing a file (read validation context) it is raised as a
%   warning instead, the non-conforming value is kept so the file remains
%   readable, and guidance on how to correct it is appended.
%
%   Callers pass a fully formed, context-neutral message describing the
%   violation. Optional CAUSES (an array of MException objects) are attached
%   as causes when erroring, and their messages are appended to the text when
%   warning, because warnings cannot carry structured causes.

    arguments
        errorId (1,1) string
        message (1,1) string
        causes (1,:) MException = MException.empty(1, 0)
    end

    if strcmp(types.util.validationContext(), 'read')
        readGuidance = ['The value read from the file is kept so the file ' ...
            'remains readable. If you maintain this file, consider ' ...
            'correcting it and re-exporting.'];

        fullMessage = message;
        for iCause = 1:numel(causes)
            fullMessage = fullMessage + " " + string(causes(iCause).message);
        end
        fullMessage = fullMessage + " " + readGuidance;

        warning(errorId, '%s', fullMessage)
    else
        exception = MException(errorId, '%s', message);
        for iCause = 1:numel(causes)
            exception = exception.addCause(causes(iCause));
        end
        throw(exception)
    end
end
