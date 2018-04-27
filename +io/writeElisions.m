function gids = writeElisions(loc_id, path)
gids = [];
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
gids = zeros(size(splitpath));

gids(1) = io.writeGroup(loc_id, splitpath{1});
for i=2:length(splitpath)
    gids(i) = io.writeGroup(gids(i-1), splitpath{i});
end
end