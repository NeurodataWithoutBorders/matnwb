function mustBeCompatibleType(value, neurodataTypeName)
% mustBeCompatibleType - Validate a neurodata type across compatible namespaces.
%
% This helper exists to preserve compatibility across NWB schema versions.
% Some HDMF common types were previously generated in the legacy `types.core`
% namespace and are now generated in `types.hdmf_common`. Validation should
% therefore accept either class when callers mean the same conceptual
% neurodata type.
%
% The function checks both compatible class names using `isa` on the fast
% path. Only if validation fails does it call `exist(..., 'class')` to
% distinguish between:
%   1) a value of the wrong type, and
%   2) missing generated NWB classes on the MATLAB path.
%
% This keeps the common case lightweight while still producing a more
% specific error message when the value is of wrong type or the classes are 
% not available.

    arguments
        value
        neurodataTypeName (1,1) string
    end

    expectedTypeNames = [...
        matnwb.common.composeFullClassName("hdmf_common", neurodataTypeName), ...
        matnwb.common.composeFullClassName("core", neurodataTypeName) ...
        ];

    isValid = any(arrayfun(@(typeName) isa(value, typeName), expectedTypeNames));

    if ~isValid
        availableTypeName = string(missing);
        for className = expectedTypeNames
            fileName = matnwb.common.internal.classname2path(className);
            if exist(fileName, 'file') == 2 % Does the class file exist on MATLAB's path?
                availableTypeName = className;
                break
            end
        end

        assert(~ismissing(availableTypeName), ...
            'NWB:Validator:ExpectedTypeMissing', ...
            ['Type validation failed because expected type classes were not ', ...
            'found on MATLAB''s search path. Ensure NWB type classes are ', ...
            'generated and present on MATLAB''s search path.'])

        error(...
            'NWB:validators:mustBeCompatibleType', ...
            'Value must be of type %s but was of type %s.', ...
            availableTypeName, class(value));
    end
end
