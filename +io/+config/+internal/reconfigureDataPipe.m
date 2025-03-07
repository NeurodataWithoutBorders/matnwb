function dataPipe = reconfigureDataPipe(dataPipe, datasetConfig)
    
    % Note: Unclear how this will work for iterators

    % Internal pipe needs to be a blueprintpipe
    assert(isa(dataPipe.internal, 'types.untyped.datapipe.BlueprintPipe'))

    % Retrieve data
    datasetData = dataPipe.internal.data;

    % Set up a new data pipe
    dataPipe = io.config.internal.configureDataPipeFromData(datasetData, datasetConfig);
end
