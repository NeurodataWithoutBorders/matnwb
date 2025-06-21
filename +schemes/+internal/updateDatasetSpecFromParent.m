function updateDatasetSpecFromParent(childDatasets, parentDatasets)

    for iDataset = 1:numel(childDatasets)
        currentDataset = childDatasets{iDataset};
        
        matchingParentDataset = schemes.internal.findMatchingParentSpec(...
            currentDataset, parentDatasets);
    
        if isempty(matchingParentDataset)
            continue
        end

        parentDatasetKeys = matchingParentDataset.keys();
        for iKey = 1:numel(parentDatasetKeys)
            currentKey = parentDatasetKeys{iKey};

            if strcmp(currentKey, 'attributes')
                if isKey(currentDataset, 'attributes')
                    schemes.internal.updateAttributeSpecFromParent(...
                        currentDataset('attributes'), ...
                        matchingParentDataset('attributes'))
                end
            
            elseif ~isKey(currentDataset, currentKey)
                currentDataset(currentKey) = matchingParentDataset(currentKey);
            end
        end
    end
end
