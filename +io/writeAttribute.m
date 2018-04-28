function writeAttribute(loc_id, tid, name, value)
    id = H5A.create(loc_id, name, tid, H5S.create('H5S_SCALAR'), 'H5P_DEFAULT');
    H5A.write(id, tid, value);
    H5A.close(id);
end