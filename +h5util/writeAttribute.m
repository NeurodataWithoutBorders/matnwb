function id = writeAttribute(loc_id, name, data, type, shape)
if nargin > 3
  typ = type;
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
id = H5A.create(loc_id, name, tid, sid, 'H5P_DEFAULT');
if ~isempty(data)
  H5A.write(id, 'H5ML_DEFAULT', data);
end

H5S.close(sid);
H5T.close(tid);

if nargout == 0
  H5A.close(id);
end
end