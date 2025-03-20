function byteSize = getDataByteSize(data)
% getDataByteSize - Get bytesize of a numeric array
    dataType = class(data);
    bytesPerDataPoint = io.getMatTypeSize(dataType);

    byteSize = numel(data) .* bytesPerDataPoint;
end
