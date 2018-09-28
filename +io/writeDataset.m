function writeDataset(fid, fullpath, type, data)
[tid, sid, data] = io.mapData2H5(fid, type, data);
did = H5D.create(fid, fullpath, tid, sid, 'H5P_DEFAULT');
H5D.write(did, tid, sid, sid, 'H5P_DEFAULT', data);
H5D.close(did);
end