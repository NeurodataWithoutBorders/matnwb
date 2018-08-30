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
if ischar(filename)
    validateattributes(filename, {'char'}, {'scalartext', 'nonempty'});
    info = h5info(filename);
    nwb = io.parseGroup(filename, info);
    return;
elseif isstring(filename)
    validateattributes(filename, {'string'}, {'nonempty'});
else
    validateattributes(filename, {'cell'}, {'nonempty'});
    assert(iscellstr(filename));
end
nwb = nwbfile.empty(length(filename), 0);
isStringArray = isstring(filename);
for i=1:length(filename)
    if isStringArray
        fnm = filename(i);
    else
        fnm = filename{i};
    end
    info = h5info(fnm);
    nwb(i) = io.parseGroup(fnm, info);
end
end