function applyChunkConfiguration(nwbObject, chunkConfiguration)
    arguments
        nwbObject (1,1) NwbFile
        chunkConfiguration (1,1) struct = io.config.readDefaultChunkConfiguration()
    end

    objectMap = nwbObject.searchFor('');
    objectKeys = objectMap.keys();

    filteredObjectMap = containers.Map();
    for i = 1:numel(objectKeys)
        thisObjectKey = objectKeys{i};
        thisNwbObject = objectMap(thisObjectKey);
        if startsWith(class(thisNwbObject), "types.") && ~startsWith(class(thisNwbObject), "types.untyped")
            filteredObjectMap(thisObjectKey) = thisNwbObject;
        end
    end
    clear objectMap
    
    objectKeys = filteredObjectMap.keys();
    for i = 1:numel(objectKeys)
        thisObjectKey = objectKeys{i};
        thisNwbObject = filteredObjectMap(thisObjectKey);

        % Todo: Find dataset properties where it makes sense to do chunking
        % I.e data, timestamps etc. Can this be determined automatically,
        % or do we need a lookup?

        dataTypeChunkOptions = io.config.internal.resolveDataTypeChunkConfig(chunkConfiguration, thisNwbObject);

        if isprop(thisNwbObject, 'data')
            if isnumeric(thisNwbObject.data)
                % Create a datapipe object for the property value.
                dataByteSize = io.config.internal.getDataByteSize(thisNwbObject.data);
                if dataByteSize > dataTypeChunkOptions.chunk_default_size
                    chunkSize = io.config.internal.computeChunkSizeFromConfig(thisNwbObject.data, dataTypeChunkOptions);
                    maxSize = size(thisNwbObject.data);

                    dataPipe = types.untyped.DataPipe( ...
                        'data', thisNwbObject.data, ...
                        'maxSize', maxSize, ...
                        'chunkSize', chunkSize, ...
                        'compressionLevel', dataTypeChunkOptions.chunk_compression_args);
                    thisNwbObject.data = dataPipe;
                end
            end
        end
    end
end
