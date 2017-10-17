function varargout = generateExtensions(corestruct, varargin)
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