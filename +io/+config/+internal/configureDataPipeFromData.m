function dataPipe = configureDataPipeFromData(numericData, datasetConfig)
% configureDataPipeFromData - Configure a DataPipe from numeric data and dataset configuration
    
    import io.config.internal.computeChunkSizeFromConfig
    import types.untyped.datapipe.properties.DynamicFilter

    chunkSize = computeChunkSizeFromConfig(numericData, datasetConfig.chunking);
    if isvector(numericData)
        % If input data is vector, we use maxSize = Inf to enforce a 1D
        % columnar representation of data in file.
        maxSize = Inf;
    else
        maxSize = size(numericData);
    end

    dataPipeArgs = {...
        "data", numericData, ...
        "maxSize", maxSize, ...
        "chunkSize", chunkSize };

    hasShuffle = ~isempty(datasetConfig.compression.prefilters)...
                 && contains(datasetConfig.compression.prefilters, 'shuffle');

    % Check if the configured compression method is DEFLATE (gzip)
    if strcmpi(datasetConfig.compression.method, "deflate") ...
            || strcmpi(datasetConfig.compression.method, "gzip")
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
            datasetConfig.compression.method, ...
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
