function classes = getSourceInfo(localdir, varargin)
schema = Schema();
classes = containers.Map;
flen = length(varargin);
for i=1:flen
  file = varargin{i};
  classes(file) = schema.read(fullfile(localdir, file));
end
end