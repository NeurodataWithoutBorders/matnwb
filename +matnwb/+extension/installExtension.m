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
%   Releases are downloaded from the Python Package Index (PyPI), where
%   NWB extensions are published with their specification files. Downloads
%   are kept in the "NWB-Extension-Source" folder in the user path.

    arguments
        extensionName (1,1) string
        version (1,1) string = "latest"
        options.savedir (1,1) string = misc.getMatnwbDir()
    end

    import matnwb.extension.internal.getPypiRelease
    import matnwb.extension.internal.downloadRelease

    downloadFolder = fullfile(userpath, "NWB-Extension-Source");
    if ~isfolder(downloadFolder); mkdir(downloadFolder); end

    T = matnwb.extension.listExtensions();
    isMatch = T.name == extensionName;

    extensionList = join( compose("  %s", [T.name]), newline );
    assert( ...
        any(isMatch), ...
        'NWB:InstallExtension:ExtensionNotFound', ...
        'Extension "%s" was not found in the extension catalog:\n', extensionList)

    release = getPypiRelease(extensionName, version);
    namespaceFilePath = downloadRelease(release, downloadFolder);

    generateExtension(namespaceFilePath, 'savedir', options.savedir);
    fprintf("Installed extension ""%s"" version %s.\n", extensionName, release.Version)
end
