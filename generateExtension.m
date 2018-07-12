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

extSchema = util.generateSchema(source);
save(fullfile('namespaces',[extSchema.name '.mat']), '-struct', 'extSchema');

%check/load dependency namespaces
extmap = util.loadNamespace(extSchema.name);

%write files
file.writeNamespace(extmap(extSchema.name));
end