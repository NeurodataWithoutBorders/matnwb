function map = generate(namespace, sources)
%GENERATE From namespace object and map of files (filename) -> (Java objects)
% export raw strings map that can be written to file. (filename) -> (String)
try
    schema = Schema();
catch
    nwbloc = fileparts(which('nwbfile'));
    javapath = fullfile(nwbloc, 'jar', 'schema.jar');
    javaaddpath(javapath);
    schema = Schema();
end

map = containers.Map;
schema.export(namespace);

