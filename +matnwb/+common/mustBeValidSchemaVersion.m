function mustBeValidSchemaVersion(versionNumber)
% mustBeValidSchemaVersion - Validate version number against available schemas
    arguments
        versionNumber (1,1) string
    end

    persistent schemaVersionNumbers

    if versionNumber == "latest"
        return % Should be resolved downstream.
    end

    versionPattern = "^\d+\.\d+\.\d+$"; % i.e 2.0.0
    if isempty(regexp(versionNumber, versionPattern, 'once'))
        error('NWB:VersionValidator:InvalidVersionNumber', ...
            "Version number should formatted as <major>.<minor>.<patch>")
    end

    % Validate supported schema version
    if isempty(schemaVersionNumbers)
        schemaListing = dir(fullfile(misc.getMatnwbDir(), 'nwb-schema'));
        schemaVersionNumbers = setdiff({schemaListing.name}, {'.', '..'});
    end
    
    if ~any(strcmp(versionNumber, schemaVersionNumbers))
        error('NWB:VersionValidator:UnsupportedSchemaVersion', ...
            "The provided version number ('%s') is not supported by this version of MatNWB", ...
            versionNumber)
    end
end
