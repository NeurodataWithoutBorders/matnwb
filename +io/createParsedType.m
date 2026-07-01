function typeInstance = createParsedType(typePath, typeName, varargin)
% createParsedType - Create a neurodata type from a specified type name
%   
%   This function generates a neurodata type instance from a given type name 
%   and a corresponding cell array of name-value pairs. It is typically used 
%   when parsing datasets or groups.
%
%   Inputs:
%       typePath - (char) Path to the dataset or group in the NWB file where the 
%                  neurodata type is parsed from.
%       typeName - (char) Name of the neurodata type to be created.
%       varargin - (cell) Cell array of name-value pairs representing the 
%                  properties of the neurodata type.
%
%   Outputs:
%       typeInstance - The generated neurodata type instance.

    [~, contextCleanup] = matnwb.common.validation.internal.context("read"); %#ok<ASGLU>
    [~, sourceCleanup] = matnwb.common.validation.internal.reportingSource(...
        "TypeName", typeName, "Path", typePath); %#ok<ASGLU>

    try
        typeInstance = feval(typeName, varargin{:}); % Create the type.
    catch exception
        newException = MException('NWB:createParsedType:TypeCreationFailed', ...
            'Failed to create object of type "%s" in file location "%s".', ...
            typeName, typePath);

        extendedCause = MException(exception.identifier, ...
            getReport(exception, "extended"));
        newException = newException.addCause(extendedCause);
        if ~isempty(exception.cause)
            for i = 1:numel(exception.cause)
                newException = newException.addCause(exception.cause{i});
            end
        end
        throw(newException)
    end

end
