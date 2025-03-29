function versionString = getSchemaVersion(filename)
fid = H5F.open(filename);
aid = H5A.open(fid, 'nwb_version');
versionString = H5A.read(aid);
H5A.close(aid);
H5F.close(fid);
if isa(versionString, 'cell')
    % Earlier MATLAB releases returns a cell instead of a char, unpack:
    versionString = versionString{1};
end
end