function nwbInstallExtension(extensionNames, version, options)
% NWBINSTALLEXTENSION - Installs a specified NWB extension.
%
% Syntax:
%  NWBINSTALLEXTENSION(extensionNames) installs Neurodata Without Borders 
%  (NWB) extensions to extend the functionality of the core NWB schemas. 
%  extensionNames is a scalar string or a string array, containing the name
%  of one or more extensions from the Neurodata Extensions Catalog. The
%  latest release of each extension is installed.
%
%  NWBINSTALLEXTENSION(extensionName, version) installs the given release
%  of one extension, for example "0.2.1".
%
%  Releases are downloaded from the Python Package Index (PyPI).
%
% Valid Extension Names (from https://nwb-extensions.github.io):
%  - "ndx-miniscope"
%  - "ndx-simulation-output"
%  - "ndx-ecog"
%  - "ndx-fret"
%  - "ndx-icephys-meta"
%  - "ndx-events"
%  - "ndx-nirs"
%  - "ndx-hierarchical-behavioral-data"
%  - "ndx-sound"
%  - "ndx-extract"
%  - "ndx-photometry"
%  - "ndx-acquisition-module"
%  - "ndx-odor-metadata"
%  - "ndx-whisk"
%  - "ndx-ecg"
%  - "ndx-franklab-novela"
%  - "ndx-photostim"
%  - "ndx-multichannel-volume"
%  - "ndx-depth-moseq"
%  - "ndx-probeinterface"
%  - "ndx-dbs"
%  - "ndx-hed"
%  - "ndx-ophys-devices"
%  - "ndx-microscopy"
%  - "ndx-pose"
%  - "ndx-fiber-photometry"
%  - "ndx-binned-spikes"
%  - "ndx-wearables"
%  - "ndx-fscv"
%  - "ndx-rate-maps"
%
% Usage: 
%  Example 1 - Install "ndx-miniscope" extension::
%
%    nwbInstallExtension("ndx-miniscope")
%
%  Example 2 - Install release 0.2.2 of "ndx-miniscope"::
%
%    nwbInstallExtension("ndx-miniscope", "0.2.2")
%
% See also:
%   matnwb.extension.listExtensions, matnwb.extension.installExtension

    arguments
        extensionNames (1,:) string {mustBeCatalogExtension} = []
        version (1,1) string = "latest"
        options.savedir (1,1) string = misc.getMatnwbDir()
    end
    if isempty(extensionNames)
        extensionList = join( compose("  %s", matnwb.extension.CatalogExtension.listNames()), newline );
        error('NWB:InstallExtension:MissingArgument', ...
            'Please specify the name of an extension. Available extensions:\n\n%s\n', extensionList)
    else
        assert(isscalar(extensionNames) || version == "latest", ...
            'NWB:InstallExtension:VersionForMultipleExtensions', ...
            'A version can only be given when installing one extension.')
        for extensionName = extensionNames
            matnwb.extension.installExtension(extensionName, version, 'savedir', options.savedir)
        end
    end
end

function mustBeCatalogExtension(extensionNames)
% mustBeCatalogExtension - Validate that names are extensions in the catalog.
%
%   Names missing from matnwb.extension.CatalogExtension are looked up in
%   the online catalog, so extensions added to the catalog after this
%   version of matnwb are accepted.
    unknownNames = extensionNames(~matnwb.extension.internal.isCatalogExtension(extensionNames));
    if ~isempty(unknownNames)
        catalogNames = matnwb.extension.CatalogExtension.listNames();
        error('NWB:InstallExtension:UnknownExtension', ...
            'Unknown extension: %s. Use one of the extensions in the catalog:\n\n%s\n', ...
            strjoin(unknownNames, ', '), join(compose("  %s", catalogNames), newline))
    end
end
