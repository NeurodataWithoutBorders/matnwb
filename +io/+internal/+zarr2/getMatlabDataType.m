function matlabDataType = getMatlabDataType(datasetDirectory, datasetInfo)
% getMatlabDataType - Resolve a MATLAB-facing datatype for a Zarr dataset.

    arguments
        datasetDirectory (1,1) string
        datasetInfo (1,1) struct
    end

    datatype = [];
    if isfield(datasetInfo, "Datatype")
        datatype = datasetInfo.Datatype;
    end

    if isCompoundDatatype(datatype)
        matlabDataType = resolveCompoundTypeDescriptor(datatype);
    else
        semanticType = lower(string(datatype));
        switch semanticType
            case {"float16", "float32", "float64"}
                matlabDataType = mapNumericType(semanticType);
            case {"int8", "int16", "int32", "int64", "uint8", "uint16", "uint32", "uint64"}
                matlabDataType = char(semanticType);
            case {"bool", "logical"}
                matlabDataType = "logical";
            case {"object"}
                matlabDataType = "types.untyped.ObjectView";
            otherwise
                matlabDataType = resolveFromRawDtype(datasetDirectory, semanticType);
        end
    end

    if isempty(matlabDataType)
        matlabDataType = class(io.internal.zarr2.readDataset(datasetDirectory, datasetInfo));
    end

    if isstring(matlabDataType)
        matlabDataType = char(matlabDataType);
    end
end

function tf = isCompoundDatatype(datatype)
    tf = isstruct(datatype) || iscell(datatype);
end

function typeDescriptor = resolveCompoundTypeDescriptor(datatype)
    fieldSpecs = normalizeCompoundFieldSpecs(datatype);
    typeDescriptor = struct();

    for iField = 1:numel(fieldSpecs)
        fieldSpec = fieldSpecs(iField);
        fieldName = string(fieldSpec.name);
        assert(strlength(fieldName) > 0, ...
            "NWB:Zarr2:InvalidCompoundField", ...
            "Compound datatype fields must define a non-empty name.")

        storageType = getCompoundFieldStorageType(fieldSpec);
        matlabFieldType = mapCompoundFieldType(storageType);
        typeDescriptor.(char(fieldName)) = char(matlabFieldType);
    end
end

function fieldSpecs = normalizeCompoundFieldSpecs(datatype)
    if isstruct(datatype)
        fieldSpecs = datatype;
        return
    end

    assert(iscell(datatype), ...
        "NWB:Zarr2:InvalidCompoundType", ...
        "Unsupported compound datatype metadata format.")

    fieldSpecs = repmat(struct("name", "", "dtype", ""), 1, numel(datatype));
    for iField = 1:numel(datatype)
        fieldSpec = datatype{iField};
        assert(iscell(fieldSpec) && ismember(numel(fieldSpec), [2, 3]), ...
            "NWB:Zarr2:InvalidCompoundField", ...
            "Compound datatype metadata must use 2- or 3-element field definitions.")
        fieldSpecs(iField).name = fieldSpec{1};
        fieldSpecs(iField).dtype = fieldSpec{2};
    end
end

function storageType = getCompoundFieldStorageType(fieldSpec)
    if isfield(fieldSpec, "dtype")
        storageType = fieldSpec.dtype;
    elseif isfield(fieldSpec, "type")
        storageType = fieldSpec.type;
    elseif isfield(fieldSpec, "storageType")
        storageType = fieldSpec.storageType;
    else
        error("NWB:Zarr2:InvalidCompoundField", ...
            "Compound datatype field `%s` does not define a supported storage type.", ...
            string(fieldSpec.name))
    end
end

function matlabFieldType = mapCompoundFieldType(storageType)
    assert(~isstruct(storageType) && ~iscell(storageType), ...
        "NWB:Zarr2:UnsupportedCompoundFieldType", ...
        "Nested or non-scalar compound field types are not supported.")

    fieldType = string(storageType);
    normalizedFieldType = lower(fieldType);

    switch normalizedFieldType
        case {"float16", "float32", "float64"}
            matlabFieldType = mapNumericType(normalizedFieldType);
            return
        case {"int8", "int16", "int32", "int64", "uint8", "uint16", "uint32", "uint64"}
            matlabFieldType = normalizedFieldType;
            return
        case {"bool", "logical"}
            matlabFieldType = "logical";
            return
        case {"object", "|o"}
            matlabFieldType = "types.untyped.ObjectView";
            return
    end

    if any(startsWith(fieldType, ["<U", ">U", "|U", "<S", ">S", "|S"]))
        matlabFieldType = "char";
        return
    end

    token = regexp(char(fieldType), '(?<code>[fiub])(?<width>\d+)$', 'names', 'once');
    assert(~isempty(token), ...
        "NWB:Zarr2:UnsupportedCompoundFieldType", ...
        "Unsupported compound field type `%s`.", fieldType)

    switch token.code
        case "f"
            matlabFieldType = mapNumericType("float" + token.width);
        case "i"
            matlabFieldType = "int" + token.width;
        case "u"
            matlabFieldType = "uint" + token.width;
        case "b"
            matlabFieldType = "logical";
    end
end

function matlabDataType = resolveFromRawDtype(datasetDirectory, semanticType)
    matlabDataType = "";

    rawDatasetInfo = io.backend.zarr2.mw.readInfo(datasetDirectory);
    if ~isfield(rawDatasetInfo, "dtype")
        return
    end

    rawType = string(rawDatasetInfo.dtype);
    if rawType == "|O"
        if semanticType == ""
            matlabDataType = "cell";
        else
            matlabDataType = semanticType;
        end
        return
    end

    token = regexp(char(rawType), '(?<code>[fiub])(?<width>\d+)$', 'names', 'once');
    if isempty(token)
        return
    end

    switch token.code
        case "f"
            matlabDataType = mapNumericType("float" + token.width);
        case "i"
            matlabDataType = "int" + token.width;
        case "u"
            matlabDataType = "uint" + token.width;
        case "b"
            matlabDataType = "logical";
    end
end

function matlabDataType = mapNumericType(semanticType)
    switch semanticType
        case "float16"
            matlabDataType = "half";
        case "float32"
            matlabDataType = "single";
        case "float64"
            matlabDataType = "double";
        otherwise
            matlabDataType = "";
    end
end
