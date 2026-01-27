function versionString = getSchemaVersion(filename)
    attributes = readZattrs(filename);
    versionString = attributes.nwb_version;
end
