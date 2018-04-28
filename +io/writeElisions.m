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

prevgid = io.writeGroup(loc_id, splitpath{1});
for i=2:length(splitpath)
    gid = io.writeGroup(prevgid, splitpath{i});
    H5G.close(prevgid);
    prevgid = gid;
end
end