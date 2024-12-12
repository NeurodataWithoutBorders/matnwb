function installExtension(extensionName, options)
% installExtension - Install NWB extension from Neurodata Extensions Catalog
%
%   matnwb.extension.nwbInstallExtension(extensionName) installs a Neurodata 
%   Without Borders (NWB) extension from the Neurodata Extensions Catalog to 
%   extend the functionality of the core NWB schemas. 

    arguments
        extensionName (1,1) string
        options.savedir (1,1) string = misc.getMatnwbDir()
    end

    import matnwb.extension.internal.downloadExtensionRepository

    repoTargetFolder = fullfile(userpath, "NWB-Extension-Source");
    if ~isfolder(repoTargetFolder); mkdir(repoTargetFolder); end

    T = matnwb.extension.listExtensions();
    isMatch = T.name == extensionName;

    extensionList = join( compose("  %s", [T.name]), newline );
    assert( ...
        any(isMatch), ...
        'NWB:InstallExtension:ExtensionNotFound', ...
        'Extension "%s" was not found in the extension catalog:\n', extensionList)
    
    repositoryUrl = T{isMatch, 'src'};

    [wasDownloaded, repoTargetFolder] = ...
        downloadExtensionRepository(repositoryUrl, repoTargetFolder, extensionName);

    if ~wasDownloaded
        error('NWB:InstallExtension:DownloadFailed', ...
            'Failed to download spec for extension "%s"', extensionName)
    end
    L = dir(fullfile(repoTargetFolder, 'spec', '*namespace.yaml'));
    assert(...
        ~isempty(L), ...
        'NWB:InstallExtension:NamespaceNotFound', ...
        'No namespace file was found for extension "%s"', extensionName ...
        )
    assert(...
        numel(L)==1, ...
        'NWB:InstallExtension:MultipleNamespacesFound', ...
        'More than one namespace file was found for extension "%s"', extensionName ...
        )
    generateExtension( fullfile(L.folder, L.name), 'savedir', options.savedir );
    fprintf("Installed extension ""%s"".\n", extensionName)
end
