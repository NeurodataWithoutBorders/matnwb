function versions = listVersionChoices(extensionName)
% listVersionChoices - List the releases of an extension for code suggestions.
%
%   versions = matnwb.extension.internal.listVersionChoices(extensionName)
%   returns the released versions of an extension on PyPI as a cell array
%   of character vectors. resources/functionSignatures.json uses it to
%   suggest the version argument of nwbInstallExtension after the user has
%   typed the extension name.
%
%   MATLAB evaluates the function while the user types, so it never
%   throws: it returns an empty cell array when extensionName is not one
%   name or PyPI does not answer within two seconds. Results are kept for
%   the MATLAB session, so each extension is looked up once.

    % Suggestions wait for this function, so a slow answer would stall typing.
    timeoutSeconds = 2;

    persistent versionsByName
    if isempty(versionsByName)
        versionsByName = containers.Map();
    end

    versions = {};
    if ~(ischar(extensionName) || (isstring(extensionName) && isscalar(extensionName)))
        return
    end
    extensionName = char(extensionName);

    if isKey(versionsByName, extensionName)
        versions = versionsByName(extensionName);
        return
    end

    try
        versions = cellstr(matnwb.extension.internal.listPypiVersions( ...
            extensionName, "Timeout", timeoutSeconds));
    catch
        % No network or no answer from PyPI: offer no suggestions this time.
        return
    end
    versionsByName(extensionName) = versions;
end
