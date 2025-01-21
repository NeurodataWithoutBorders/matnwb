function applyChunkConfiguration(nwbObject, chunkConfiguration, options)
% applyChunkConfiguration - Apply chunk configuration to datasets of an NWB object
    
    arguments
        nwbObject (1,1) types.untyped.MetaClass
        chunkConfiguration (1,1) struct = io.config.readDefaultChunkConfiguration() % Todo: class for this...?
        options.OverrideExisting (1,1) logical = false
    end
    
    import io.config.internal.resolveDataTypeChunkConfig

    if isa(nwbObject, 'NwbFile')
        neurodataObjects = getNeurodataObjectsFromNwbFile(nwbObject);
    else
        neurodataObjects = {nwbObject};
    end

    for iNeurodataObject = 1:numel(neurodataObjects)
        thisNeurodataObject = neurodataObjects{iNeurodataObject};
        thisNeurodataClassName = class(thisNeurodataObject);
        
        % Need to keep track of this. A dataset can be defined across
        % multiple levels of the class hierarchy, the lowest class should
        % take precedence
        processedDatasets = string.empty;

        isFinished = false;
        while ~isFinished % Iterate over type and it's ancestor types (superclasses)

            datasetNames = schemes.listDatasetsOfNeurodataType( thisNeurodataClassName );

            for thisDatasetName = datasetNames % Iterate over all datasets of a type...
    
                if ismember(thisDatasetName, processedDatasets)
                    continue
                end

                datasetConfig = resolveDataTypeChunkConfig(...
                    chunkConfiguration, ...
                    thisNeurodataObject, ...
                    thisDatasetName);
    
                datasetData = thisNeurodataObject.(thisDatasetName);
        
                if isnumeric(datasetData)
                    % Create a datapipe object for a numeric dataset value.
                    dataByteSize = io.config.internal.getDataByteSize(datasetData);
                    if dataByteSize > datasetConfig.target_chunk_size.value
                        dataPipe = io.config.internal.configureDataPipeFromData(datasetData, datasetConfig);
                    end
                elseif isa(datasetData, 'types.untyped.DataPipe')
                    if options.OverrideExisting
                        dataPipe = io.config.internal.reconfigureDataPipe(datasetData, datasetConfig);
                    end
                elseif isa(datasetData, 'types.untyped.DataStub')
                    % pass
                    %error('Not implemented for files obtained by nwbRead')
                else
                    disp( class(datasetData) )
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
