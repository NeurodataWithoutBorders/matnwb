function names = listExtensionChoices()
% listExtensionChoices - List the catalog extensions for code suggestions.
%
%   names = matnwb.extension.internal.listExtensionChoices() returns the
%   names of the extensions in the Neurodata Extensions Catalog as a cell
%   array of character vectors. resources/functionSignatures.json uses it
%   to suggest the first argument of nwbInstallExtension.
%
%   MATLAB evaluates the function while the user types, so it never
%   throws: it returns an empty cell array when the catalog cannot be read.

    try
        extensionTable = matnwb.extension.listExtensions();
        names = cellstr(extensionTable.name);
    catch
        % No network or no answer from the catalog: offer no suggestions this time.
        names = {};
    end
end
