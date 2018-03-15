function generateCore(core, varargin)
% GENERATECORE Generate Matlab classes from NWB core schema files
%   registry = GENERATECORE(core)  Generate classes (Matlab m-files) from the
%   NWB:N core namespace file.
%
%   registry = GENERATECORE(core,extension_paths,...)  Generate classes for the
%   core namespace as well as one or more extenstions.  Each input filename
%   should be an NWB namespace file.
%
%   Output files are generated placed in a '+types' subdirectory in the
%   current working directory.
%
%   GENERATECORE returns a struct that acts as a type registry.  This
%   contains metadata the will be used when generating code for extension
%   NWB schemas.
%
%   Example:
%      generateCore('schema\core\nwb.namespace.yaml');
%
%   See also GENERATEEXTENSIONS
validateattributes(core, {'char', 'string'}, {'scalartext'});
cs = util.generateSchema(core);
save(fullfile('namespaces','core.mat'), '-struct', 'cs');

%write core files
namespaceMap = util.loadNamespace('core');
file.writeNamespace(namespaceMap('core'));

%write extensions
for i=1:length(varargin)
    generateExtension(varargin{i});
end
end