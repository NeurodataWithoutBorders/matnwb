function classes = getSourceInfo(localdir, varargin)
schema = Schema();
classes = containers.Map;
files = fullfile(localdir, varargin);
for i=1:length(files)
  classes(varargin{i}) = schema.read(files{i});
end
end