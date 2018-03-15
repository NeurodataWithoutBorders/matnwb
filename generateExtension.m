function generateExtension(source)
% GENERATEEXTENSIONS Generate Matlab classes from NWB extension schema file
%   registry = GENERATECORE(registry,extension_path...)  Generate classes 
%   (Matlab m-files) from one or more NWB:N schema extension namespace 
%   files.  A registry of already generated core types is used to resolve 
%   dependent types.
%
%   Output files are generated placed in a '+types' subdirectory in the
%   current working directory.
%
%   [registry,~,~]=GENERATEEXTENSIONS(...) The registry is a struct of
%   gnerated core types.  This contains metadata the will be used when 
%   generating code for extension NWB schemas.
%
%   [~,namespace,~]=GENERATEEXTENSIONS(...) Returns a list of registered
%   namespaces.
%
%   [~,~,dependencies]=GENERATEEXTENSIONS(...) Returns a list of
%   dependencies as reported by the namespace schema file.
%   
%   Example:
%      registry=generateCore('schema\core\nwb.namespace.yaml');
%      core=generateExtensions(registry,'schema\core\myextension.namespace.yaml')
% 
%   See also GENERATECORE
validateattributes(source, {'char', 'string'}, {'scalartext'});

extSchema = util.generateSchema(source);
save(fullfile('namespaces',[extSchema.name '.mat']), extSchema);

%check/load dependency namespaces
extmap = util.loadNamespace(extSchema.name);

%write files
file.writeNamespace(extmap(extSchema.name));
end