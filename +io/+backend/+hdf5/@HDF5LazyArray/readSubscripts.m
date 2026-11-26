function data = readSubscripts(obj, selection)
% readSubscripts - Read every combination of per-dimension indices.
%
% Each dimension's indices are split into runs and isolated indices (see
% io.space.findShapes), and the combination of all of them is selected as
% one union of hyperslabs (see io.space.getReadSpace) and read in one call.
% The dataspace and the read use the same open dataset, so each call opens
% the file once.
    shapes = cell(1, numel(selection));
    for iDimension = 1:numel(selection)
        if ischar(selection{iDimension})
            shapes{iDimension} = {io.space.shape.Block('stop', obj.dims(iDimension))};
        else
            shapes{iDimension} = io.space.findShapes(selection{iDimension});
        end
    end

    fileId = H5F.open(obj.Filename);
    datasetId = H5D.open(fileId, obj.DatasetPath);
    spaceId = H5D.get_space(datasetId);
    [readSpaceId, memorySpaceId] = io.space.getReadSpace(shapes, spaceId);
    H5S.close(spaceId);

    data = H5D.read(datasetId, 'H5ML_DEFAULT', memorySpaceId, readSpaceId, 'H5P_DEFAULT');
    data = hdf2mat(datasetId, data);

    H5S.close(memorySpaceId);
    H5S.close(readSpaceId);
    H5D.close(datasetId);
    H5F.close(fileId);
end
