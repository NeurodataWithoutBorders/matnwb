function classes = generateClasses(varargin)
classes = struct();
if nargin > 0
  for i=1:nargin
    srcdir = varargin{i};
    validateattributes(srcdir, {'char', 'string'}, {'scalartext'});
    dirlist = dir(srcdir);
    for j=1:length(dirlist)
      d = dirlist(j);
      if ~d.isdir
        yml = yaml.parse(fullfile(srcdir, d.name));
        classes = yaml.util.structUniqUnion(classes, yml);
      end
    end
  end
  classes = yaml.util.resolveDependencies(classes);
end
end