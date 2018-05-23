function writeGroup(fid, fullpath)
plist = 'H5P_DEFAULT';
parts = split(fullpath, '/');
parts = parts(~cellfun('isempty', parts)); %remove empty parts
if isempty(parts)
    return;
end
buffer = repmat(fid, 1, length(parts)+1);
create = false;
for i=1:length(parts)
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

for i=length(buffer):-1:2
    H5G.close(buffer(i));
end
end