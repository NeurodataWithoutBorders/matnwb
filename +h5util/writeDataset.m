function id = writeDataset(loc_id, name, data, type, shape)
if nargin > 3 && ~strcmp(type, 'any')
  typ = type;
elseif iscellstr(data)
  typ = 'string';
else
  typ = class(data);
end

if nargin > 4
  sz = shape;
else
  sz = size(data);
end

tid = h5util.mat2hdf_typeid(typ);
sid = h5util.defineSpace(sz);
id = H5D.create(loc_id, name, tid, sid, 'H5P_DEFAULT');
H5D.write(id, tid, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', data);

H5S.close(sid);
H5T.close(tid);

if nargout == 0
  H5D.close(id);
end
end