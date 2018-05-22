function writeAttribute(loc_id, type, name, value)
tid = io.getBaseType(type, value);
sid = H5S.create('H5S_SCALAR');
id = H5A.create(loc_id, name, tid, sid, 'H5P_DEFAULT');
H5A.write(id, tid, value .');
H5A.close(id);
H5S.close(sid);
end