function generateAllClasses(varargin)
%schema + all extension classes
c = yaml.generateClasses('schema', varargin{:});
cfn = fieldnames(c);
for i=1:length(cfn)
  nm = cfn{i};
  file.writeClass(nm, c.(nm), 'types');
end
end