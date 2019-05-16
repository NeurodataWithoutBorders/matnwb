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
%  See also GENERATECORE, GENERATEEXTENSION, NWBFILE, NWBEXPORT
if ischar(filename)
    validateattributes(filename, {'char'}, {'scalartext', 'nonempty'});
    info = h5info(filename);
    
    %check for .specloc
    attr_names = {info.Attributes.Name};
    specloc_ind = strcmp('.specloc', attr_names);
    if any(specloc_ind)
        ref_data = info.Attributes(specloc_ind).Value;
        fid = H5F.open(filename);
        attr_id = H5A.open(fid, '.specloc');
        blacklist = H5R.get_name(attr_id, 'H5R_OBJECT', ref_data);
        H5A.close(attr_id);
        H5F.close(fid);
        info.Attributes(specloc_ind) = [];
    else
        blacklist = '';
    end
    nwb = io.parseGroup(filename, info, blacklist);
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
