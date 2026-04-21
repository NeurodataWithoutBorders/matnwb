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
        
        % If dtype and shape keys are not defined for a dataset, mark these so
        % the class generator will not create validation functions using
        % default values. Validation will instead be handled in the included
        % class when dtype is omitted on the including dataset.
        
        if ~isKey(spec, 'dtype')
            spec('skip_dtype_validation') = true; %#ok<NASGU> spec is a handle object (containers.Map), so this assignment persists even if the variable is not returned.
        end
        if ~isKey(spec, 'shape')
            spec('shape') = nan; %#ok<NASGU> spec is a handle object (containers.Map), so this assignment persists even if the variable is not returned.
        end
    end
end
