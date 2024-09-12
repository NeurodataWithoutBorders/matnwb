function typeInstance = createParsedType(typePath, typeName, varargin)
% createParsedType - Create a neurodata type from specified type name
%   
%   This function is used when parsing datasets or groups to create a 
%   neurodata type instance given a type name and a cell array of name value 
%   pairs for that type.
%
%   The function captures warnings with the ID 
%   "NWB:CheckUnset:InvalidProperties" and enhances the warning message by 
%   including specific details about the dataset or group in the NWB file where 
%   the issue occurred.

    warnState = warning('off', 'NWB:CheckUnset:InvalidProperties');
    cleanupObj = onCleanup(@(s) warning(warnState)); % Make sure warning state is reset

    [lastWarningMessage, lastWarningID] = lastwarn('', ''); % Clear last warning

    typeInstance = feval(typeName, varargin{:}); % Create the type.

    [warningMessage, warningID] = lastwarn();
    if ~isempty(warningMessage)

        if strcmp( warningID, 'NWB:CheckUnset:InvalidProperties' )
            
            clear cleanupObj % Reset last warning state

            if endsWith(warningMessage, '.')
                warningMessage = warningMessage(1:end-1);
            end

            updatedMessage = sprintf('%s at file location "%s"\n', warningMessage, typePath);
            
            disclaimer = 'The properties in question were dropped while reading the file.';

            suggestion = [...
                'Consider checking the schema version of the file with '...
                '`util.getSchemaVersion(filename)` and comparing with the ' ...
                'YAML namespace version present in nwb-schema/core/nwb.namespace.yaml' ];        
            
            warning(warningID, '%s\n%s\n\n%s', updatedMessage, disclaimer, suggestion)
        else
            warning(warningID, warningMessage)
        end
    else
        lastwarn(lastWarningMessage, lastWarningID); % Reset last warning
    end
end
