function id = writeGroup(loc_id, name)
plist = 'H5P_DEFAULT';
try
    %do not write if the path already exists
    id = H5G.open(loc_id, name, plist);
catch
    id = H5G.create(loc_id, name, plist, plist, plist);
end
end