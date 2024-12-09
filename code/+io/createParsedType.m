function typeInstance = createParsedType(typePath, typeName, varargin)
% createParsedType - Create a neurodata type from a specified type name
%   
%   This function generates a neurodata type instance from a given type name 
%   and a corresponding cell array of name-value pairs. It is typically used 
%   when parsing datasets or groups.
%
%   Warnings with the ID "NWB:CheckUnset:InvalidProperties" are captured, and 
%   the warning message is enhanced with specific details about the dataset or 
%   group in the NWB file where the issue occurred.
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


    warnState = warning('off', 'NWB:CheckUnset:InvalidProperties');
    cleanupObj = onCleanup(@(s) warning(warnState)); % Make sure warning state is reset later

    [lastWarningMessage, lastWarningID] = lastwarn('', ''); % Clear last warning

    typeInstance = feval(typeName, varargin{:}); % Create the type.

    [warningMessage, warningID] = lastwarn();

    % Handle any warnings if they occurred.
    if ~isempty(warningMessage)
        if strcmp( warningID, 'NWB:CheckUnset:InvalidProperties' )
            
            clear cleanupObj % Reset last warning state

            if endsWith(warningMessage, '.')
                warningMessage = warningMessage(1:end-1);
            end

            updatedMessage = sprintf('%s at file location "%s"\n', warningMessage, typePath);
            
            disclaimer = 'NB: The properties in question were dropped while reading the file.';

            suggestion = [...
                'Consider checking the schema version of the file with '...
                '`util.getSchemaVersion(filename)` and comparing with the ' ...
                'YAML namespace version present in nwb-schema/core/nwb.namespace.yaml' ];        
            
            warning(warningID, '%s\n%s\n\n%s', updatedMessage, disclaimer, suggestion)
        else
            % Pass, warning has already been displayed
        end
    else
        lastwarn(lastWarningMessage, lastWarningID); % Reset last warning
    end
end
