function writeDataset(fid, fullpath, type, data, forceArray)
[tid, sid, data] = io.mapData2H5(fid, type, data, forceArray);
did = H5D.create(fid, fullpath, tid, sid, 'H5P_DEFAULT');
H5D.write(did, tid, sid, sid, 'H5P_DEFAULT', data);
H5D.close(did);
end