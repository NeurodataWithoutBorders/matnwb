function nwbInstallExtension(extensionNames, options)
% NWBINSTALLEXTENSION - Installs a specified NWB extension.
%
% Syntax:
%  NWBINSTALLEXTENSION(extensionNames) installs Neurodata Without Borders 
%  (NWB) extensions to extend the functionality of the core NWB schemas. 
%  extensionNames is a scalar string or a string array, containing the name
%  of one or more extensions from the Neurodata Extensions Catalog
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
%
% Usage: 
%  Example 1 - Install "ndx-miniscope" extension::
%
%    nwbInstallExtension("ndx-miniscope")
%
% See also:
%   matnwb.extension.listExtensions, matnwb.extension.installExtension

    arguments
        extensionNames (1,:) string {mustBeMember(extensionNames, [...
            "ndx-miniscope", ...
            "ndx-simulation-output", ...
            "ndx-ecog", ...
            "ndx-fret", ...
            "ndx-icephys-meta", ...
            "ndx-events", ...
            "ndx-nirs", ...
            "ndx-hierarchical-behavioral-data", ...
            "ndx-sound", ...
            "ndx-extract", ...
            "ndx-photometry", ...
            "ndx-acquisition-module", ...
            "ndx-odor-metadata", ...
            "ndx-whisk", ...
            "ndx-ecg", ...
            "ndx-franklab-novela", ...
            "ndx-photostim", ...
            "ndx-multichannel-volume", ...
            "ndx-depth-moseq", ...
            "ndx-probeinterface", ...
            "ndx-dbs", ...
            "ndx-hed", ...
            "ndx-ophys-devices" ...
            ] ...
        )} = []
        options.savedir (1,1) string = misc.getMatnwbDir()
    end
    if isempty(extensionNames)
        T = matnwb.extension.listExtensions();
        extensionList = join( compose("  %s", [T.name]), newline );
        error('NWB:InstallExtension:MissingArgument', ...
            'Please specify the name of an extension. Available extensions:\n\n%s\n', extensionList)
    else
        for extensionName = extensionNames
            matnwb.extension.installExtension(extensionName, 'savedir', options.savedir)
        end
    end
end

