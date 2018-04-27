function writeDataset(loc_id, name, data)



if isscalar(data)
    sid = H5S.create('H5S_SCALAR');
else
    sid = H5S.create('H5S_SIMPLE');
end
did = H5D.create(loc_id, name, tid, sid, 'H5P_DEFAULT');

end