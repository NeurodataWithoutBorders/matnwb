function did = writeDataset(loc_id, name, type, data)
tid = io.getBaseType(type, data);
if isscalar(data) || strcmp(type, 'char')
    sid = H5S.create('H5S_SCALAR');
else
    if isvector(data)
        nd = 1;
        dims = length(data);
    else
        nd = ndims(data);
        dims = size(data);
    end
    sid = H5S.create_simple(nd, dims, []);
end
did = H5D.create(loc_id, name, tid, sid, 'H5P_DEFAULT');
H5D.write(did, tid, sid, sid, 'H5P_DEFAULT', data');
end