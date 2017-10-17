function varargout = generateExtensions(varargin)
namespace = cell(1, nargin);
depends = {};
c = struct();
for i=1:nargin
  extspc = varargin{i};
  validateattributes(extspc, {'string', 'char'}, {'scalartext'});
  [e, extnm, extdepends] = yaml.genFromNamespace(extspc);
  c = util.structUniqUnion(c, e);
  namespace{i} = extnm;
  depends = [depends extdepends];
end

if nargout >= 1
  varargout{1} = c;
end

if nargout >= 2
  varargout{2} = namespace;
end

if nargout > 2
  varargout{3} = depends;
end
end