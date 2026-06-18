function reportSchemaViolation(errorId, message)
% reportSchemaViolation - Raise a schema-validation issue as an error or warning.
%   In the default (strict) validation context the issue is raised as an
%   error. When parsing a file (read validation context) it is raised as a
%   warning instead, the non-conforming value is kept so the file remains
%   readable, and guidance on how to correct it is appended.
%
%   Callers pass a fully formed, context-neutral message describing the
%   violation (what is required and what the value is). The read-context
%   guidance is appended here so it stays consistent across validators.

    arguments
        errorId (1,1) string
        message (1,1) string
    end

    if strcmp(types.util.validationContext(), 'read')
        readGuidance = ['The value read from the file is kept so the file ' ...
            'remains readable. If you maintain this file, consider ' ...
            'correcting it and re-exporting.'];
        warning(errorId, '%s', message + " " + readGuidance)
    else
        error(errorId, '%s', message)
    end
end
