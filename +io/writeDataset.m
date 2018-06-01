function writeDataset(fid, fullpath, type, data)
tid = io.getBaseType(type, data);
if isscalar(data) || strcmp(type, 'char')
    sid = H5S.create('H5S_SCALAR');
else
    if isvector(data)
        nd = 1;
        dims = length(data);
    else
        nd = ndims(data);
        dims = size(data);
    end
    
    if iscellstr(data)
        data = io.padCellStr(data, max(cellfun('length', data)));
        data = cell2mat(data .');
    end
    sid = H5S.create_simple(nd, fliplr(dims), []);
end
if any(strcmp({'types.untyped.RegionView' 'types.untyped.ObjectView'}, type))
    data = io.getRefData(fid, data);
end
did = H5D.create(fid, fullpath, tid, sid, 'H5P_DEFAULT');
H5D.write(did, tid, sid, sid, 'H5P_DEFAULT', data);
H5D.close(did);
end