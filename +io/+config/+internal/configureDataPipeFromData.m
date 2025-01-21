function dataPipe = configureDataPipeFromData(numericData, datasetConfig)
% configureDataPipeFromData - Configure a DataPipe from numeric data and dataset configuration
    
    import io.config.internal.computeChunkSizeFromConfig
    import types.untyped.datapipe.properties.DynamicFilter

    chunkSize = computeChunkSizeFromConfig(numericData, datasetConfig);
    maxSize = size(numericData);

    dataPipeArgs = {...
        "data", numericData, ...
        "maxSize", maxSize, ...
        "chunkSize", chunkSize };

    hasShuffle = contains(datasetConfig.compression.prefilters, 'shuffle');

    if strcmpi(datasetConfig.compression.algorithm, "Deflate")
        % Use standard compression filters
        dataPipeArgs = [ dataPipeArgs, ...
            {'hasShuffle', hasShuffle, ...
            'compressionLevel', datasetConfig.compression.level} ...
            ];
    else 
        % Create property list of custom filters for dataset creation
        compressionFilter = DynamicFilter( ...
            datasetConfig.compression.algorithm, ...
            datasetConfig.compression.level );
        
        if hasShuffle
            shuffleFilter = types.untyped.datapipe.properties.Shuffle();
            filters = [shuffleFilter compressionFilter];
        else
            filters = compressionFilter;
        end
        dataPipeArgs = [ dataPipeArgs, ...
            {'filters', filters} ];
    end

    % Create the datapipe.
    dataPipe = types.untyped.DataPipe( dataPipeArgs{:} );
end