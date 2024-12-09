function latestVersion = findLatestSchemaVersion()
% findLatestSchemaVersion - Find latest available schema version.

    schemaListing = dir(fullfile(misc.getMatnwbDir(), 'nwb-schema'));
    schemaVersionNumbers = setdiff({schemaListing.name}, {'.', '..'});

    % Split each version number into major, minor, and patch components
    versionComponents = cellfun(@(v) sscanf(v, '%d.%d.%d'), ...
        schemaVersionNumbers, 'UniformOutput', false);
    
    % Convert the components into an array for easy comparison
    versionMatrix = cat(2, versionComponents{:})';
    
    % Find the row with the highest version number, weighting major
    % and minor with factors of 6 and 3 respectively
    [~, latestIndex] = max(versionMatrix * [1e6; 1e3; 1]); % Weight major, minor, patch
    
    % Return the latest version
    latestVersion = schemaVersionNumbers{latestIndex};
end