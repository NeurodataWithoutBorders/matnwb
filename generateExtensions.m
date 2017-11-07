function varargout = generateExtensions(corestruct, varargin)
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
namespaces = {'core'};
depends = {};
for i=1:(nargin-1)
  extspc = varargin{i};
  if (ischar(extspc) || isstring(extspc)) && ~strcmp(extspc, 'dryrun')
    [e, extnm, extdepends] = yaml.genFromNamespace(extspc);
    corestruct = util.structUniqUnion(corestruct, e);
    namespaces{length(namespaces)+1} = extnm;
    depends = [depends extdepends];
  end
end

missingdep = setdiff(depends, namespaces);
if ~isempty(missingdep)
  error('generateClasses: Missing dependencies { %s }', strjoin(missingdep, ', '));
end

corestruct = yaml.util.resolveDependencies(corestruct);

for cfn=fieldnames(corestruct)'
  nm = cfn{1};
  file.writeClass(nm, corestruct.(nm), 'types');
end

if nargout >= 1
  varargout{1} = corestruct;
end

if nargout >= 2
  varargout{2} = namespaces;
end

if nargout > 2
  varargout{3} = depends;
end
end