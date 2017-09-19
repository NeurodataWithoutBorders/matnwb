function map = read(filename)
  javaaddpath(fullfile('+yaml', 'jar', 'yaml.jar'));
  map = yaml.read(filename);
end