function latestVersion = findLatestSchemaVersion()
% findLatestSchemaVersion - Find latest available schema version.

    schemaListing = dir(fullfile(misc.getMatnwbDir(), 'nwb-schema'));

    % Keep only entries named as version numbers; ignores hidden files like .DS_Store
    versionNumbers = regexp({schemaListing.name}, '^\d+\.\d+\.\d+$', 'match', 'once');
    keep = ~cellfun(@isempty, versionNumbers);
    versionNumbers = versionNumbers(keep);

    % Split each version number into major, minor, and patch components
    versionComponents = cellfun(@(v) sscanf(v, '%d.%d.%d'), ...
        versionNumbers, 'UniformOutput', false);
    
    % Convert the components into an array for easy comparison
    versionMatrix = cat(2, versionComponents{:})';
    
    % Find the row with the highest version number, weighting major
    % and minor with factors of 6 and 3 respectively
    [~, latestIndex] = max(versionMatrix * [1e6; 1e3; 1]); % Weight major, minor, patch
    
    % Return the latest version
    latestVersion = versionNumbers{latestIndex};
end
