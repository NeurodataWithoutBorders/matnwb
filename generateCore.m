function varargout = generateCore(core, varargin)
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

[c, ~, ~] = yaml.genFromNamespace(core); %should not be any namespace dependencies
[varargout{1:nargout}] = generateExtensions(c, varargin{:});
end