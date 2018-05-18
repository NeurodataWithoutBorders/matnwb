function [did, refs] = writeDataset(loc_id, name, path, type, data, refs)
if strcmp(type, 'ref')
    refs(path) = data.path;
elseif strcmp(type, 'table') %compound
    keyboard;
end

tid = io.getBaseType(type);
if isscalar(data)
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
H5D.write(did, tid, sid, sid, 'H5P_DEFAULT', data);
end