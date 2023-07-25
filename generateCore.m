function generateCore(varargin)
    % GENERATECORE Generate Matlab classes from NWB core schema files
    %   GENERATECORE()  Generate classes (Matlab m-files) from the
    %   NWB:N core namespace file. By default, generates off of the most recent nwb-schema
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
    
    latestVersion = '2.6.0';
    
    if nargin == 0 || strcmp(varargin{1}, 'savedir')
        version = latestVersion;
    else
        version = varargin{1};
        validateattributes(version, {'char', 'string'}, {'scalartext'}, 'generateCore', 'version', 1);
        version = char(version);
        varargin = varargin(2:end);
    end
    
    if strcmp(version, 'latest')
        version = latestVersion;
    end
    
    schemaPath = fullfile(misc.getMatnwbDir(), 'nwb-schema', version);
    corePath = fullfile(schemaPath, 'core', 'nwb.namespace.yaml');
    commonPath = fullfile(schemaPath,...
        'hdmf-common-schema', ...
        'common',...
        'namespace.yaml');
    assert(2 == exist(corePath, 'file'),...
        'NWB:GenerateCore:MissingCoreSchema',...
        'Cannot find suitable core namespace for schema version `%s`',...
        version);
    if 2 == exist(commonPath, 'file')
        generateExtension(commonPath, varargin{:});
    end
    generateExtension(corePath, varargin{:});
end