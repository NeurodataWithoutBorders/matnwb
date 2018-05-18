function writeAttribute(loc_id, type, name, value)
    tid = io.getBaseType(type);
    if strcmp(type, 'char')
        sid = H5S.create_simple(1, length(value), []);
    else
        sid = H5S.create('H5S_SCALAR');
    end
    id = H5A.create(loc_id, name, tid, sid, 'H5P_DEFAULT');
    H5A.write(id, tid, value);
    H5A.close(id);
    H5S.close(sid);
end