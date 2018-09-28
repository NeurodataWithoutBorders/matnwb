function writeAttribute(fid, type, fullpath, data)
[tid, sid, data] = io.mapData2H5(fid, type, data);
data = data .';
[path, name] = io.pathParts(fullpath);
if isempty(path)
    path = '/'; %weird case if the property is in root
end
oid = H5O.open(fid, path, 'H5P_DEFAULT');
try
    id = H5A.create(oid, name, tid, sid, 'H5P_DEFAULT');
catch ME
    %when a dataset is copied over, it also copies all attributes with it.
    %So we have to open the Attribute for overwriting instead.
    if contains(ME.message, 'H5A_create    attribute already exists')
        H5A.delete(oid, name);
        id = H5A.create(oid, name, tid, sid, 'H5P_DEFAULT');
    else
        H5O.close(oid);
        H5S.close(sid);
        rethrow(ME);
    end
end
H5A.write(id, tid, data);
H5A.close(id);
H5S.close(sid);
H5O.close(oid);
end