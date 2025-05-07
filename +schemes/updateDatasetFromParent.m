function updateDatasetFromParent(childDatasets, parentDatasets)

    for iDataset = 1:numel(childDatasets)
        currentDataset = childDatasets{iDataset};
          
        matchingParentDataset = [];

        if isKey(currentDataset, 'name')
            currentDatasetName = currentDataset('name');

            for iParentDataset = 1:numel(parentDatasets)
                if isKey( parentDatasets{iParentDataset}, 'name' ) ...
                        && strcmp(parentDatasets{iParentDataset}('name'), currentDatasetName)
                    matchingParentDataset = parentDatasets{iParentDataset};
                end
            end

        elseif isKey(currentDataset, 'neurodata_type_inc')
            currentDatasetType = currentDataset('neurodata_type_inc');

            for iParentDataset = 1:numel(parentDatasets)
                if isKey( parentDatasets{iParentDataset}, 'neurodata_type_inc' ) ...
                        && strcmp(parentDatasets{iParentDataset}('neurodata_type_inc'), currentDatasetType)
                    matchingParentDataset = parentDatasets{iParentDataset};
                end
            end

        else
            error('not ok')
        end
    

        if isempty(matchingParentDataset)
            continue
        end

        datasetKeys = matchingParentDataset.keys();
        for iKey = 1:numel(datasetKeys)
            currentKey = datasetKeys{iKey};
    
            if ~isKey(currentDataset, currentKey)
                currentDataset(currentKey) = matchingParentDataset(currentKey);
            end
        end
    end
end
