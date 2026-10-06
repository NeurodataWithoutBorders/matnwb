function versionNumbers = listSchemaVersions()
% listSchemaVersions - List the NWB schema versions bundled with MatNWB
%
% Syntax:
%  versionNumbers = matnwb.common.listSchemaVersions() returns the version
%  numbers of the schemas in the nwb-schema folder of MatNWB, sorted from
%  oldest to newest.
%
% Output Arguments:
%  - versionNumbers (string) - Row vector of version numbers, e.g. "2.11.0"
%
% The code suggestions for generateCore in resources/functionSignatures.json
% call this function, so the suggested versions follow the bundled schemas.

    schemaListing = dir(fullfile(misc.getMatnwbDir(), 'nwb-schema'));

    % Keep only folders named as version numbers; ignores hidden files like .DS_Store
    isVersionFolder = [schemaListing.isdir] ...
        & ~cellfun('isempty', regexp({schemaListing.name}, '^\d+\.\d+\.\d+$', 'once'));
    versionNumbers = string({schemaListing(isVersionFolder).name});

    % Sort numerically, so that 2.10.0 comes after 2.9.0
    versionComponents = double(split(versionNumbers(:), ".", 2));
    [~, sortOrder] = sortrows(versionComponents);
    versionNumbers = reshape(versionNumbers(sortOrder), 1, []);
end
