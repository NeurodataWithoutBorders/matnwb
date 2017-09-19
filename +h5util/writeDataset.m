function id = writeDataset(loc_id, name, data, type, size)
if nargin > 4
  typ = type;
else
  typ = class(data);
end

if nargin > 3
  sz = size;
else
  sz = size(data);
end

tid = h5helper.mat2hdf_typeid(typ);
sid = h5helper.defineSpace(sz);
id = H5D.create(loc_id, name, tid, sid, 'H5P_DEFAULT');
H5D.write(id, tid, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', data);

H5S.close(sid);
H5T.close(tid);

if nargout == 0
  H5D.close(id);
end
end