function writeDataset(fid, fullpath, type, data, varargin)
assert(isempty(varargin) || iscellstr(varargin),...
    'options should be character arrays.');
[tid, sid, data] = io.mapData2H5(fid, type, data, varargin{:});
[~, dims, ~] = H5S.get_simple_extent_dims(sid);
try
    dcpl = H5P.create('H5P_DATASET_CREATE');
    if any(strcmp('forceChunking', varargin))
        H5P.set_chunk(dcpl, dims)
    end
    did = H5D.create(fid, fullpath, tid, sid, dcpl);
    H5P.close(dcpl);
catch ME
    if contains(ME.message, 'name already exists')
        did = H5D.open(fid, fullpath);
        if ~isempty(dims)
            H5D.set_extent(did, dims);
        end
    else
        rethrow(ME);
    end
end
H5D.write(did, tid, sid, sid, 'H5P_DEFAULT', data);
H5D.close(did);
if isa(tid, 'H5ML.id')
    H5T.close(tid);
end
H5S.close(sid);
end