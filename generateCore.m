function generateCore(version, options)
    % GENERATECORE Generate Matlab classes from NWB core schema files
    %   GENERATECORE()  Generate classes (Matlab m-files) from the
    %   NWB core namespace file. By default, generates off of the most recent nwb-schema
    %   release.
    %
    %   GENERATECORE(version)  Generate classes for the
    %   core namespace of the listed version.
    %
    %   A cache of schema data is generated in the 'namespaces' subdirectory in
    %   the current working directory.  This is for allowing cross-referencing
    %   classes between multiple namespaces.
    %
    %   Output files are generated placed in a '+types' subdirectory in the
    %   current working directory.
    %
    %   GENERATECORE(__, 'savedir', saveDirectory) Generates the core class
    %   files in the specified directory.
    %
    %   Example:
    %      generateCore();
    %      generateCore('2.2.3');
    %
    %   See also GENERATEEXTENSION

    arguments
        version (1,1) string {matnwb.common.mustBeValidSchemaVersion} = "latest"
        options.savedir (1,1) string = misc.getMatnwbDir()
    end

    if version == "latest"
        version = matnwb.common.findLatestSchemaVersion();
    end

    schemaPath = fullfile(misc.getMatnwbDir(), "nwb-schema", version);
    corePath = fullfile(schemaPath, "core", "nwb.namespace.yaml");
    commonPath = fullfile(schemaPath, ...
        "hdmf-common-schema", ...
        "common", ...
        "namespace.yaml");
    assert(isfile(corePath), ...
        'NWB:GenerateCore:MissingCoreSchema', ...
        'Cannot find suitable core namespace for schema version `%s`', ...
        version);

    namespaceFiles = corePath;
    if isfile(commonPath)
        % Important: generate common before core if common is available
        namespaceFiles = [commonPath, namespaceFiles];
    end
    generateExtension(namespaceFiles{:}, 'savedir', options.savedir);
end
