function latestVersion = findLatestSchemaVersion()
% findLatestSchemaVersion - Find latest available schema version.

    versionNumbers = matnwb.common.listSchemaVersions();
    latestVersion = char(versionNumbers(end));
end
