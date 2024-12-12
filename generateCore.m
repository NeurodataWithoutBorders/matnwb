function generateCore(version, options)
% GENERATECORE - Generate Matlab classes from NWB core schema files
%
% Syntax:
%  GENERATECORE() Generate classes (Matlab m-files) from the
%  NWB core namespace file. By default, generates off of the most recent 
%  nwb-schema release.
%
%  GENERATECORE(version)  Generate classes for the
%  core namespace of the listed version.
%
%  GENERATECORE(__, Name, Value)  Generate classes based on optional 
%  name-value pairs controlling the output .
%
%  A cache of schema data is generated in the ``namespaces`` subdirectory in
%  the matnwb root directory.  This is for allowing cross-referencing
%  classes between multiple namespaces.
%
%  Output files are placed in a ``+types`` subdirectory in the
%  matnwb root directory directory.
%
% Usage:
%  Example 1 - Generate core schemas for the latest version of NWB::
%
%    generateCore();
%
%  Example 2 - Generate core schemas for an older version of NWB::
%
%     generateCore('2.2.3');
%
%  Example 3 - Generate and save classes in a custom location::
%
%     %  Generates the core class files in the specified directory.
%     generateCore('savedir', saveDirectory)
%
% See also:
%   generateExtension

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
