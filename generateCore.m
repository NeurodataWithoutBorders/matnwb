function generateCore(version)
% GENERATECORE Generate Matlab classes from NWB core schema files
%   GENERATECORE()  Generate classes (Matlab m-files) from the
%   NWB:N core namespace file. By default, generates off of the most recent nwb-schema
%   release.
%
%   GENERATECORE(version)  Generate classes for the
%   core namespace of that version
%
%   A cache of schema data is generated in the 'namespaces' subdirectory in
%   the current working directory.  This is for allowing cross-referencing
%   classes between multiple namespaces.
%
%   Output files are generated placed in a '+types' subdirectory in the
%   current working directory.
%
%   Example:
%      generateCore();
%      generateCore('2.2.3');
%
%   See also GENERATEEXTENSION

if nargin == 0
    version = '2.3.0';
else
    validateattributes(version, {'char'}, {'scalartext'});
end

matNwbLocation = misc.getMatnwbDir();
schemaPath = fullfile(matNwbLocation, 'nwb-schema', version);
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
    generateExtension(commonPath);
end
generateExtension(corePath);
end