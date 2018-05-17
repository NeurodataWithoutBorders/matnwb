function [did, refs] = writeDataset(loc_id, path, name, type, data, refs)
if strcmp(type, 'ref')
    keyboard;
elseif strcmp(type, 'table') %compound
    keyboard;
end

tid = io.getBaseType(type);
if isscalar(data)
    sid = H5S.create('H5S_SCALAR');
else
    sid = H5S.create('H5S_SIMPLE');
end
did = H5D.create(loc_id, name, tid, sid, 'H5P_DEFAULT');
H5D.write(did, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', data);
end