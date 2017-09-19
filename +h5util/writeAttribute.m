function id = writeAttribute(loc_id, name, data, type, size)
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
id = H5A.create(loc_id, name, tid, sid, 'H5P_DEFAULT');
H5A.write(id, 'H5ML_DEFAULT', data);

H5S.close(sid);
H5T.close(tid);

if nargout == 0
  H5A.close(id);
end
end