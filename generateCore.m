function generateCore(core, varargin)
% GENERATECORE Generate Matlab classes from NWB core schema files
%   GENERATECORE(core)  Generate classes (Matlab m-files) from the
%   NWB:N core namespace file.
%
%   GENERATECORE(core,extension_paths,...)  Generate classes for the
%   core namespace as well as one or more extenstions.  Each input filename
%   should be an NWB namespace file.
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
%
%   See also GENERATEEXTENSION
validateattributes(core, {'char', 'string'}, {'scalartext'});
cs = util.generateSchema(core);
if 7 ~= exist('namespaces','dir')
    mkdir('namespaces')
end
save(fullfile('namespaces','core.mat'), '-struct', 'cs');

%write core files
namespaceMap = util.loadNamespace('core');
file.writeNamespace(namespaceMap('core'));

%write extensions
for i=1:length(varargin)
    generateExtension(varargin{i});
end
end