function generateCore(core, varargin)
[c, ~, ~] = yaml.genFromNamespace(core); %should not be any namespace dependencies
namespaces = {'core'};
[extc, extnmspc, depends] = generateExtensions(varargin{:});
namespaces = [namespaces extnmspc];
c = util.structUniqUnion(c, extc);
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