function writeDataset(loc_id, name, type, data, attributes)
if strcmp(type, 'ref')
    keyboard;
elseif strcmp(type, 'compound')
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
for i=1:length(attributes)
    attr = attributes(i);
    io.writeAttribute(did, io.getBaseType(attr.dtype), attr.name, attr.value);
end
H5D.close(did);
end