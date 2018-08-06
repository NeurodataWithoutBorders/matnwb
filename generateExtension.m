function generateExtension(source)
% GENERATEEXTENSIONS Generate Matlab classes from NWB extension schema file
%   GENERATECORE(extension_path...)  Generate classes 
%   (Matlab m-files) from one or more NWB:N schema extension namespace 
%   files.  A registry of already generated core types is used to resolve 
%   dependent types.
%   
%   A cache of schema data is generated in the 'namespaces' subdirectory in
%   the current working directory.  This is for allowing cross-referencing
%   classes between multiple namespaces.
%
%   Output files are generated placed in a '+types' subdirectory in the
%   current working directory.
%   
%   Example:
%      generateCore('schema\core\nwb.namespace.yaml');
%      generateExtensions('schema\core\myextension.namespace.yaml')
% 
%   See also GENERATECORE
validateattributes(source, {'char', 'string'}, {'scalartext'});

%find jar from source and generate Schema
javapath = fullfile(fileparts(which('nwbfile')), 'jar', 'schema.jar');
if ~any(strcmp(javaclasspath(), javapath))
    javaaddpath(javapath);
end
[localpath, ~, ~] = fileparts(source);
[filenames, nm, dep] = yaml.getNamespaceInfo(source);
schema = yaml.getSourceInfo(localpath, filenames{:});
extSchema = struct('name', nm, 'schema', schema, 'dependencies', {dep});
namespacePath = fullfile('.', 'namespaces');
if 7 ~= exist(namespacePath, 'dir')
    mkdir(namespacePath);
end
save(fullfile(namespacePath,[extSchema.name '.mat']), '-struct', 'extSchema');

%check/load dependency namespaces
extmap = schemes.loadNamespace(extSchema.name);

%write files
file.writeNamespace(extmap(extSchema.name));
end