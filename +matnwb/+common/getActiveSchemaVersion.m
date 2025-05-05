function versionStr = getActiveSchemaVersion()
% getActiveSchemaVersion - Retrieve the active version of the NWB format specification
%
% Description:
%   MatNWB dynamically generates MATLAB classes representing (neuro)data
%   types for a specific version of the NWB format. This is a utility
%   function for retrieving the version of the NWB specification schemas
%   that was used for generating the current set of type classes on
%   MATLAB's search path.
%
% Syntax:
%   versionStr = matnwb.common.getActiveSchemaVersion() retrieves the version 
%   string for the currently generated version of the NWB format specification 
%   in MatNWB.
%
% Output Arguments:
%   versionStr - A string representing the active format version,
%                or an empty string if no version is generated.

    if exist(fullfile('+types','+core','Version'), 'file') == 2
        versionStr = types.core.Version();
    else
        versionStr = '';
    end
end
