function expandFieldsInheritedByInclusion(node)
    % Todo: Loop over subgroups ?
        
    % Loop over datasets
    if isKey(node, 'datasets')
        includedDatasets = node('datasets');
        for i = 1:numel(includedDatasets)
            datasetSpec = includedDatasets{i};
            lockKeysInheritedThroughInclusion(datasetSpec)
        end
    end
end

function lockKeysInheritedThroughInclusion(spec)
    if (isKey(spec, 'neurodata_type_inc') || isKey(spec, 'data_type_inc')) && ...
            ~(isKey(spec, 'neurodata_type_def') || isKey(spec, 'data_type_def'))
        % "inheritance" by inclusion
        
        % If dtype and shape keys are not defined for a dataset, set these to
        % 'any' and 'null' respectively. This is done to ensure the class
        % generator will not create validation functions for a dataset using 
        % default values and instead, the validation will be handled in the
        % "included" class.
        
        if ~isKey(spec, 'dtype')
            spec('dtype') = 'any';
        end
        if ~isKey(spec, 'shape')
            spec('shape') = nan; %#ok<NASGU> spec is a handle object (containers.Map), so this assignment persists even if the variable is not returned.
        end
    end
end
