function applyDatasetConfiguration(nwbObject, datasetConfiguration, options)
% applyDatasetConfiguration - Apply dataset configuration to datasets of an NWB object
    
    arguments
        nwbObject (1,1) NwbFile
        datasetConfiguration (1,1) struct = io.config.readDatasetConfiguration()
        options.OverrideExisting (1,1) logical = false
    end
    
    import io.config.internal.resolveDatasetConfigForDataType

    neurodataObjects = getNeurodataObjectsFromNwbFile(nwbObject);

    for iNeurodataObject = 1:numel(neurodataObjects)
        thisNeurodataObject = neurodataObjects{iNeurodataObject};
        thisNeurodataClassName = class(thisNeurodataObject);
        
        % A dataset can be defined on multiple levels of the class hierarchy,
        % so need to keep track of which datasets have been processed.
        % Todo: This needs a better explanation
        processedDatasets = string.empty;

        isFinished = false;
        while ~isFinished % Iterate over type and it's ancestor types (superclasses)

            datasetNames = schemes.listDatasetsOfNeurodataType( thisNeurodataClassName );
            for thisDatasetName = datasetNames % Iterate over all datasets of a type
    
                if ismember(thisDatasetName, processedDatasets)
                    continue
                end

                datasetConfig = resolveDatasetConfigForDataType(...
                    datasetConfiguration, ...
                    thisNeurodataObject, ...
                    thisDatasetName);
    
                datasetData = thisNeurodataObject.(thisDatasetName);
        
                if isnumeric(datasetData)
                    % Create a datapipe object for a numeric dataset value.
                    dataSizeBytes = io.config.internal.getDataByteSize(datasetData);
                    targetChunkSizeBytes = io.config.internal.getTargetChunkSizeInBytes(datasetConfig.chunking);
                    if dataSizeBytes > targetChunkSizeBytes
                        dataPipe = io.config.internal.configureDataPipeFromData(datasetData, datasetConfig);
                    end
                elseif isa(datasetData, 'types.untyped.DataPipe')
                    if options.OverrideExisting
                        dataPipe = io.config.internal.reconfigureDataPipe(datasetData, datasetConfig);
                    end
                elseif isa(datasetData, 'types.untyped.DataStub')
                    % todo
                    % error('Not implemented for files obtained by nwbRead')
                else
                    % todo: types.untyped.Set ?
                    % disp( class(datasetData) )
                end
    
                if exist('dataPipe', 'var')
                    thisNeurodataObject.(thisDatasetName) = dataPipe;
                    processedDatasets = [processedDatasets, thisDatasetName]; %#ok<AGROW>
                    clear dataPipe
                end
            end

            parentType = matnwb.common.getParentType(thisNeurodataClassName);

            if isempty(parentType)
                isFinished = true;
            else
                thisNeurodataClassName = parentType;
            end
        end
    end
end

function neurodataObjects = getNeurodataObjectsFromNwbFile(nwbObject)
% getNeurodataObjectsFromNwbObject - Return all neurodata objects in a NwbFile object
    
    objectMap = nwbObject.searchFor('types.');

    neurodataObjects = objectMap.values();
    neurodataClassNames = cellfun(@(c) class(c), neurodataObjects, 'uni', 0);

    toIgnore = startsWith(neurodataClassNames, "types.untyped");
    neurodataObjects(toIgnore) = [];
end
