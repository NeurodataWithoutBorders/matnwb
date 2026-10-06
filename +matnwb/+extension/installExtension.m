function installExtension(extensionName, version, options)
% installExtension - Install NWB extension from Neurodata Extensions Catalog
%
%   matnwb.extension.installExtension(extensionName) installs the latest
%   release of a Neurodata Without Borders (NWB) extension from the
%   Neurodata Extensions Catalog to extend the functionality of the core
%   NWB schemas.
%
%   matnwb.extension.installExtension(extensionName, version) installs the
%   given release of the extension, for example "0.2.1".
%
%   extensionName must be an extension in the catalog. It is checked
%   against matnwb.extension.CatalogExtension, and against the online
%   catalog when CatalogExtension does not list it, so an extension added
%   to the catalog after this version of matnwb can be installed.
%
%   Releases are downloaded from the Python Package Index (PyPI), where
%   NWB extensions are published with their specification files. Downloads
%   are kept in the "NWB-Extension-Source" folder in the user path.
%
%   The NWB extensions that the release requires are installed first, at
%   the version it pins or the latest version that meets its conditions.
%   A required extension that is already installed at a suitable version
%   is kept; one at another version is replaced. Required extensions do
%   not have to be in the Neurodata Extensions Catalog.

    arguments
        extensionName (1,1) string
        version (1,1) string = "latest"
        options.savedir (1,1) string = misc.getMatnwbDir()
    end

    downloadFolder = fullfile(userpath, "NWB-Extension-Source");
    if ~isfolder(downloadFolder); mkdir(downloadFolder); end

    if ~matnwb.extension.internal.isCatalogExtension(extensionName)
        catalogNames = matnwb.extension.CatalogExtension.listNames();
        error('NWB:InstallExtension:ExtensionNotFound', ...
            'Extension "%s" was not found in the extension catalog. Use one of:\n\n%s\n', ...
            extensionName, join(compose("  %s", catalogNames), newline))
    end

    matnwb.extension.internal.installRelease( ...
        extensionName, version, options.savedir, downloadFolder)
end
