function schema = loadSchema()
%LOADSCHEMA Summary of this function goes here
%   Detailed explanation goes here
try
    schema = Schema();
catch
    nwb_loc = fileparts(which('NwbFile'));
    java_loc = fullfile(nwb_loc, 'jar', 'schema.jar');
    javaaddpath(java_loc);
    schema = Schema();
end
end

