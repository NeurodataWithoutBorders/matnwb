function writeAttribute(fid, fullpath, data, varargin)

[tid, sid, data] = io.mapData2H5(fid, data, varargin{:});
[path, name] = io.pathParts(fullpath);
if isempty(path)
    path = '/'; % Weird case if the property is in root
end
oid = H5O.open(fid, path, 'H5P_DEFAULT');
h5CleanupObj = onCleanup(@(sid_, oid_) closeSpaceAndObject(sid, oid) );

try
    id = H5A.create(oid, name, tid, sid, 'H5P_DEFAULT');
catch ME
    % When a dataset is copied over, it also copies all attributes with it.
    % So we have to open the Attribute for overwriting instead.
    % this may also happen if the attribute is a reference
    if contains(ME.message, 'H5A__create    attribute already exists')...
        || contains(ME.message, 'H5A_create    attribute already exists')
        H5A.delete(oid, name);
        id = H5A.create(oid, name, tid, sid, 'H5P_DEFAULT');
    else
        rethrow(ME);
    end
end
if ~isempty(data)
    H5A.write(id, tid, data);
end
H5A.close(id);

function closeSpaceAndObject(spaceId, objectId)
    H5S.close(spaceId);
    H5O.close(objectId);
end
end