function id = writeGroup(loc_id, name)
plist = 'H5P_DEFAULT';
id = H5G.create(loc_id, name, plist, plist, plist);
end