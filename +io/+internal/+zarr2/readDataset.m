function datasetValue = readDataset(datasetDirectory, datasetInfo, rawDatasetValue)
% readDataset - Read and normalize a Zarr dataset for matnwb.

    arguments
        datasetDirectory (1,1) string
        datasetInfo (1,1) struct
        rawDatasetValue = []
    end

    if isempty(rawDatasetValue)
        rawDatasetInfo = io.backend.zarr2.mw.readInfo(datasetDirectory);
        semanticType = getDatasetSemanticType(datasetInfo);

        if isfield(rawDatasetInfo, "dtype") && isObjectRawDtype(rawDatasetInfo.dtype)
            datasetValue = io.internal.zarr2.readObjectArray(datasetDirectory);
            datasetValue = postprocessObjectDatasetValue(datasetValue, semanticType);
        else
            datasetValue = io.backend.zarr2.mw.readArray(datasetDirectory);
        end
    else
        datasetValue = rawDatasetValue;
    end

    datasetValue = normalizeDatasetDimensions(datasetValue);
end

function semanticType = getDatasetSemanticType(datasetInfo)
    semanticType = "";
    if isfield(datasetInfo, "Datatype") ...
            && (ischar(datasetInfo.Datatype) || isstring(datasetInfo.Datatype))
        semanticType = string(datasetInfo.Datatype);
        return
    end

    attributes = datasetInfo.Attributes;
    if isempty(attributes)
        return
    end

    attributeNames = {attributes.Name};
    zarrTypeMask = strcmp(attributeNames, "zarr_dtype");
    if any(zarrTypeMask)
        semanticType = string(attributes(find(zarrTypeMask, 1, "first")).Value);
    end
end

function tf = isObjectRawDtype(rawDtype)
    tf = (ischar(rawDtype) || isstring(rawDtype)) && strcmp(string(rawDtype), "|O");
end

function datasetValue = postprocessObjectDatasetValue(datasetValue, semanticType)
    if iscell(datasetValue) && isscalar(datasetValue)
        datasetValue = datasetValue{1};
    end

    if semanticType == "object"
        if isstruct(datasetValue) && isfield(datasetValue, "path")
            datasetValue = types.untyped.ObjectView(datasetValue.path);
        elseif iscell(datasetValue)
            datasetValue = cellfun(@(item) types.untyped.ObjectView(item.path), ...
                datasetValue, 'UniformOutput', false);
        end
    end
end

function datasetValue = normalizeDatasetDimensions(datasetValue)
    if ischar(datasetValue) || (isstring(datasetValue) && isscalar(datasetValue))
        return
    end

    if iscell(datasetValue) && isscalar(datasetValue)
        datasetValue = datasetValue{1};
        return
    end

    if ndims(datasetValue) <= 1
        return
    elseif ismatrix(datasetValue)
        datasetValue = datasetValue.';
    else
        datasetValue = permute(datasetValue, ndims(datasetValue):-1:1);
    end
end
