function info = getExtensionInfo(extensionName)
% getExtensionInfo - Get metadata for the specified Neurodata extension
%
% Syntax:
%  info = matnwb.extension.GETEXTENSIONINFO(extensionName) Returns a struct 
%  with metadata/information about the specified extension. The extension
%  must be registered in the Neurodata Extension Catalog.
%
% Input Arguments:
%  - extensionName (string) - 
%    Name of a Neurodata Extension, e.g "ndx-miniscope".
%
% Output Arguments:
%  - info (struct) - 
%    Struct with metadata / information for the specified extension. The struct 
%    has the following fields: 
%    
%    - name - The name of the extension.
%    - version - The current version of the extension.
%    - last_updated - A timestamp indicating when the extension was last updated.
%    - src - The URL to the source repository or homepage of the extension.
%    - license - The license type under which the extension is distributed.
%    - maintainers - A cell array or array of strings listing the maintainers.
%    - readme - A string containing the README documentation or description.
%
% Usage:
%  Example 1 - Retrieve and display information for the 'ndx-miniscope' extension::
% 
%    info = matnwb.extension.getExtensionInfo('ndx-miniscope');
% 
%    % Display the version of the extension.
%    fprintf('Extension version: %s\n', info.version);
%
% See also: 
%   matnwb.extension.listExtensions

    arguments
        extensionName (1,1) string
    end

    T = matnwb.extension.listExtensions();
    isMatch = T.name == extensionName;
    extensionList = join( compose("  %s", [T.name]), newline );
    assert( ...
        any(isMatch), ...
        'NWB:DisplayExtensionMetadata:ExtensionNotFound', ...
        'Extension "%s" was not found in the extension catalog:\n%s', extensionName, extensionList)
    info = table2struct(T(isMatch, :));
end
