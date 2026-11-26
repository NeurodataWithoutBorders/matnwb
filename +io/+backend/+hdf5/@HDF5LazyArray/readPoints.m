function values = readPoints(obj, subscripts)
% readPoints - Read single elements with one point selection.
%
% H5S.select_elements takes zero-based coordinates in HDF5's dimension
% order, one column per element.
    numPoints = size(subscripts, 1);

    fileId = H5F.open(obj.Filename);
    datasetId = H5D.open(fileId, obj.DatasetPath);
    spaceId = H5D.get_space(datasetId);
    readSpaceId = H5S.copy(spaceId);
    H5S.close(spaceId);
    H5S.select_elements(readSpaceId, 'H5S_SELECT_SET', fliplr(subscripts).' - 1);
    memorySpaceId = H5S.create_simple(1, numPoints, numPoints);

    data = H5D.read(datasetId, 'H5ML_DEFAULT', memorySpaceId, readSpaceId, 'H5P_DEFAULT');
    data = hdf2mat(datasetId, data);

    H5S.close(memorySpaceId);
    H5S.close(readSpaceId);
    H5D.close(datasetId);
    H5F.close(fileId);

    if isstruct(data)
        fieldNames = fieldnames(data);
        for iField = 1:numel(fieldNames)
            data.(fieldNames{iField}) = data.(fieldNames{iField})(:);
        end
        values = data;
    else
        values = data(:);
    end
end
