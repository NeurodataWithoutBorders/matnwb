function nwb = nwbRead(filename)
%NWBREAD Reads an NWB file.
%  nwb = nwbRead(filename) Reads the nwb file at filename and returns an
%  NWBFile object representing its contents.
%  
%  Requires that core and extension NWB types have been generated
%  and reside in a 'types' package on the matlab path.
%  
%  Example: 
%    %Generate Matlab code for the NWB objects from the core schema.
%    %This only needs to be done once.
%    generateCore('schema\core\nwb.namespace.yaml');
%    %Now we can read nwb files!
%    nwb=nwbRead('data.nwb');
%  
%  See also GENERATECORE, GENERATEEXTENSIONS, NWBFILE, NWBEXPORT
validateattributes(filename, {'char', 'string'}, {'scalartext'});
info = h5info(filename);

[nwb, links, refs] = io.parseGroup(filename, info);

% we need full filepath to process this part.
if java.io.File(filename).isAbsolute
  ff = filename;
else
  ff = fullfile(pwd, filename);
end
keyboard;
%process refs
%process links
[fp, ~, ~] = fileparts(ff);
end