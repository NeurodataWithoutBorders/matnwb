function writeGroup(fid, fullpath)
plist = 'H5P_DEFAULT';
if startsWith(fullpath, '/')
    fullpath = fullpath(2:end);
end

if endsWith(fullpath, '/')
    fullpath = fullpath(1:end-1);
end

if isempty(fullpath)
    return;
end

partsIdx = strfind(fullpath, '/');
partsIdx(end+1) = length(fullpath);

base_id = [];
for i=length(partsIdx):-1:1
    try
        base_id = H5G.open(fid, fullpath(1:partsIdx(i)), plist);
        break;
    catch
    end
end

if ~isempty(base_id) && i == length(partsIdx)
    %nothing to write
    H5G.close(base_id);
    return;
end

% write phase
if isempty(base_id)
    base_id = fid;
    ioffset = 1;
    offsetStart = 1;
else
    ioffset = i+1;
    offsetStart = partsIdx(i)+1;
end
offsets = [offsetStart partsIdx(ioffset:end-1)+1];
partsIdx = partsIdx(ioffset:end);
closeBuf = repmat(H5ML.id, length(partsIdx),1);
gid = base_id;
for i=1:length(partsIdx)
    gid = H5G.create(gid, fullpath(offsets(i):partsIdx(i)), plist, plist, plist);
    closeBuf(i) = gid;
end

for i=length(closeBuf):-1:1
    H5G.close(closeBuf(i));
end

if base_id ~= fid
    H5G.close(base_id);
end
end