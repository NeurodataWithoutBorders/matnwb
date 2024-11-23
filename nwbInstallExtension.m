function nwbInstallExtension(extensionNames)
% nwbInstallExtension - Installs a specified NWB extension.
%
% Usage:
%   nwbInstallExtension(extensionNames) installs Neurodata Without Borders 
%   (NWB) extensions to extend the functionality of the core NWB schemas. 
%   extensionNames is a scalar string or a string array, containing the name
%   of one or more extensions from the Neurodata Extensions Catalog
%
% Valid Extension Names:
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
% Example:
%   % Install the "ndx-miniscope" extension
%   nwbInstallExtension("ndx-miniscope")
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
    end
    if isempty(extensionNames)
        T = matnwb.extension.listExtensions();
        extensionList = join( compose("  %s", [T.name]), newline );
        error("Please specify the name of an extension. Available extensions:\n\n%s\n", extensionList)
    else
        for extensionName = extensionNames
            matnwb.extension.installExtension(extensionName)
        end
    end
end
