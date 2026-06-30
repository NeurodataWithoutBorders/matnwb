classdef ValidationContext
% ValidationContext - Runtime context for schema validation reporting.
%   ValidationContext identifies when schema validation is running so
%   matnwb.common.validation.reportSchemaViolation can choose whether a
%   violation should warn or error.
%
%   READ is used while constructing MatNWB objects from existing files.
%   Schema violations warn in this context so files with non-conforming
%   values remain readable.
%
%   EDIT is the default context for user-created or modified in-memory
%   objects. Schema violations error unless a validator explicitly requests
%   warning behavior.
%
%   WRITE is used while exporting NWB files. Schema violations always error
%   in this context so MatNWB does not write invalid files.

    enumeration
        READ
        EDIT
        WRITE
    end
end
