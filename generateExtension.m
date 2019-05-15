function generateExtension(source)
% GENERATEEXTENSION Generate Matlab classes from NWB extension schema file
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
%      generateExtension('schema\myext\myextension.namespace.yaml')
% 
%   See also GENERATECORE
validateattributes(source, {'char', 'string'}, {'scalartext'});

%find jar from source and generate Schema
nwbloc = fileparts(mfilename('fullpath'));
javapath = fullfile(nwbloc, 'jar', 'schema.jar');
if ~any(strcmp(javaclasspath(), javapath))
    javaaddpath(javapath);
end
schema = Schema();
[localpath, ~, ~] = fileparts(source);
assert(2 == exist(source, 'file'),...
    'MATNWB:FILE', 'Path to file `%s` could not be found.', source);
fid = fopen(source);
namespace_map = schema.read(fread(fid, '*char') .');
fclose(fid);
namespace = spec.getNamespaceInfo(namespace_map);

schema_map = containers.Map;
for i=1:length(namespace.filenames)
    filename = namespace.filenames{i};
    fid = fopen(fullfile(localpath, filename));
    schema_map(filename) = fread(fid, '*char') .';
    fclose(fid);
end
schema = spec.getSourceInfo(schema_map);

extSchema = struct('name', namespace.name,...
    'schema', schema,...
    'dependencies', {namespace.dependencies},...
    'version', namespace.version);
namespacePath = fullfile(nwbloc, 'namespaces');
if 7 ~= exist(namespacePath, 'dir')
    mkdir(namespacePath);
end
save(fullfile(namespacePath,[extSchema.name '.mat']), '-struct', 'extSchema');

%check/load dependency namespaces
extmap = schemes.loadNamespace(extSchema.name);

%write files
file.writeNamespace(extmap(extSchema.name));
end
