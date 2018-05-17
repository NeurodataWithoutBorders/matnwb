function gid = writeElisions(loc_id, path)
gid = [];
if ~contains(path, '/')
    return;
end
if startsWith(path, '/')
    path = path(2:end);
end
if isempty(path)
    return;
end

splitpath = split(path, '/');

prevgid = loc_id;
for i=1:length(splitpath)
    try
        %do not write if the path already exists
        gid = H5G.open(prevgid, splitpath{i}, 'H5P_DEFAULT');
    catch
        %group dne
        gid = io.writeGroup(prevgid, splitpath{i});
    end
    if prevgid ~= loc_id
        H5G.close(prevgid);
    end
    prevgid = gid;
end
end