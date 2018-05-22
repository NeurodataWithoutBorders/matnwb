function id = writeGroup(fid, fullpath)
plist = 'H5P_DEFAULT';
parts = split(fullpath, '/');
buffer = repmat(fid, size(parts));
create = false;
for i=1:length(parts)
    if isempty(parts{i})
        continue;
    end
    if create
        gid = H5G.create(buffer(i), parts{i}, plist, plist, plist);
    else
        try
            gid = H5G.open(buffer(i), parts{i}, plist);
        catch
            create = true;
            gid = H5G.create(buffer(i), parts{i}, plist, plist, plist);
        end
    end
    buffer(i+1) = gid;
end

id = buffer(end);
buffer(end) = [];
for i=length(buffer):-1:1
    H5G.close(buffer(i));
end
end