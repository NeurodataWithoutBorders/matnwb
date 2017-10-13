function generateClasses(varargin)
corenmspc = fullfile('schema', 'core', 'nwb.namespace.yaml');
[c, ~, ~] = yaml.genFromNamespace(corenmspc); %should not be any namespace dependencies

namespaces = {'core'};
depends = {};
for i=1:nargin
  extspc = varargin{i};
  validateattributes(extspc, {'string', 'char'}, {'scalartext'});
  [e, extnm, extdepends] = yaml.genFromNamespace(extspc);
  c = util.structUniqUnion(c, e);
  namespaces{length(namespaces)+1} = extnm;
  depends = [depends extdepends];
end
missingdep = setdiff(depends, namespaces);
if ~isempty(missingdep)
  error('generateClasses: Missing dependencies { %s }', strjoin(missingdep, ', '));
end

c = yaml.util.resolveDependencies(c);

for cfn=fieldnames(c)'
  nm = cfn{1};
  file.writeClass(nm, c.(nm), 'types');
end
end