function dataPipe = configureDataPipeFromData(numericData, datasetConfig)
% configureDataPipeFromData - Configure a DataPipe from numeric data and dataset configuration
    
    import io.config.internal.computeChunkSizeFromConfig
    import types.untyped.datapipe.properties.DynamicFilter

    chunkSize = computeChunkSizeFromConfig(numericData, datasetConfig.chunking);
    maxSize = size(numericData);

    dataPipeArgs = {...
        "data", numericData, ...
        "maxSize", maxSize, ...
        "chunkSize", chunkSize };

    hasShuffle = ~isempty(datasetConfig.compression.prefilters)...
                 && contains(datasetConfig.compression.prefilters, 'shuffle');

    if strcmpi(datasetConfig.compression.algorithm, "Deflate")
        if isempty(datasetConfig.compression.parameters) ...
                || ~isfield(datasetConfig.compression.parameters, 'level')
            defaultCompressionLevel = 3;
            warning('NWB:DataPipeConfiguration:LevelParameterNotSet', ...
                ['The dataset configuration does not contain a value for ', ...
                'the "level" parameter of the Deflate filter. The default ', ...
                'value %d will be used.'], defaultCompressionLevel)
            compressionLevel = defaultCompressionLevel;
        else
            compressionLevel = datasetConfig.compression.parameters.level;
        end
        % Use standard compression filters
        dataPipeArgs = [ dataPipeArgs, ...
            {'hasShuffle', hasShuffle, ...
            'compressionLevel', compressionLevel} ...
            ];
    else
        % Create property list of custom filters for dataset creation
        parameters = struct2cell(datasetConfig.compression.parameters);
        compressionFilter = DynamicFilter( ...
            datasetConfig.compression.algorithm, ...
            parameters{:} );
        
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
