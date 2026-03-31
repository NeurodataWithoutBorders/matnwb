function parsed = parseDataset(filename, info, fullpath, blacklist)
% parseDataset - Read an HDF5 dataset and return it as named map entries.
%
% Syntax:
%  parsed = io.parseDataset(filename, info, fullpath, blacklist) parses the
%  dataset identified by FULLPATH in the HDF5 file FILENAME using metadata
%  from INFO.
%
% Input arguments:
%  - filename  - Path to the HDF5 file.
%  - info      - Dataset metadata structure, typically obtained from h5info.
%  - fullpath  - Full HDF5 path to the dataset.
%  - blacklist - Attribute names or rules to exclude when parsing attributes.
%
% Output argument:
%  - parsed - containers.Map with the following entries:
%
%      parsed('datasetName')
%          The parsed dataset value (untyped) or typed object (typed).
%
%      parsed('datasetName_attrName')
%          Dataset attributes not consumed during typed object creation,
%          or all attributes for untyped datasets.
%
% Notes:
%  - The primary map key is the dataset leaf name from INFO.Name, not
%    FULLPATH.
%  - For typed datasets, attributes are considered consumable if their
%    names match public properties of the neurodata type class. Consumed
%    attributes are used to construct the typed object and are not
%    promoted into the output map.
%  - HDF5 reference datasets are fully read and resolved.
%  - Scalar datasets are read eagerly and postprocessed according to their
%    datatype.
%  - For non-scalar datasets, chunked numeric datasets are represented as
%    DataPipe, other non-empty datasets as DataStub, and empty datasets as
%    [].

    arguments
        filename (1,:) char
        info struct
        fullpath (1,:) char
        blacklist struct = struct('attributes', {{}}, 'groups', {{}})
    end

    [parsedAttributes, typeInfo] = ...
        io.parseAttributes(filename, info.Attributes, fullpath, blacklist);

    datasetTypeName = typeInfo.typename;
    isTypedDataset = ~isempty(datasetTypeName);

    % Open an HDF5 dataset handle for reading the dataset value
    fid = H5F.open(filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
    fidCleanup = onCleanup(@() H5F.close(fid));
    
    did = H5D.open(fid, fullpath);
    didCleanup = onCleanup(@() H5D.close(did));
    
    % Read and postprocess the dataset value, or create a lazy data proxy 
    % when appropriate
    datatype = info.Datatype;
    dataspace = info.Dataspace;
    if strcmp(datatype.Class, 'H5T_REFERENCE')
        % Load all H5T references. This is required, unfortunately also a 
        % bottleneck
        tid = H5D.get_type(did);
        data = io.parseReference(did, tid, H5D.read(did));
        H5T.close(tid);
    elseif strcmp(dataspace.Type, 'scalar')
        data = H5D.read(did);

        switch datatype.Class
            case 'H5T_STRING'
                if verLessThan('MATLAB', '9.8')
                    % MATLAB 2020a fixed string support for HDF5, making
                    % reading strings "consistent" with regular use.
                    data = data .';
                end
                datadim = size(data);
                if datadim(1) > 1
                    %multidimensional strings should become cellstr
                    data = strtrim(mat2cell(data, ones(datadim(1), 1), datadim(2)));
                end
            case 'H5T_ENUM'
                if io.isBool(datatype.Type)
                    data = io.internal.h5.postprocess.toLogical(data);
                else
                    warning('NWB:Dataset:UnknownEnum', ...
                        ['Encountered unknown enum under field `%s` with %d members. ' ...
                        'Will be read as cell array of characters.'], ...
                        info.Name, length(datatype.Type.Member));
                    data = io.internal.h5.postprocess.toEnumCellStr(data, datatype.Type);
                end
            case 'H5T_COMPOUND'
                isScalar = true;
                data = io.parseCompound(did, data, isScalar);
        end
    else % non scalar
        sid = H5D.get_space(did);
        pid = H5D.get_create_plist(did);
        isChunked = H5P.get_layout(pid) == H5ML.get_constant_value('H5D_CHUNKED');

        tid = H5D.get_type(did);
        class_id = H5T.get_class(tid);
        isNumeric = class_id == H5ML.get_constant_value('H5T_INTEGER')...
            || class_id == H5ML.get_constant_value('H5T_FLOAT');
        if isChunked && isNumeric
            data = types.untyped.DataPipe('filename', filename, 'path', fullpath);
        elseif any(dataspace.Size == 0)
            data = [];
        else
            matlabDataType = io.internal.h5.datatype.datatypeInfoToMatlabType(datatype, info.Name);
            data = types.untyped.DataStub(filename, fullpath, dataspace.Size, matlabDataType);
        end
        H5T.close(tid);
        H5P.close(pid);
        H5S.close(sid);
    end

    % Prepare output
    datasetName = info.Name;
    parsed = containers.Map;

    if isTypedDataset
        [typeProperties, unconsumedAttributes] = ...
            splitAttributes(parsedAttributes, properties(datasetTypeName));
        typeProperties('data') = data;
        kwargs = io.map2kwargs(typeProperties);
        parsed(datasetName) = io.createParsedType(fullpath, datasetTypeName, kwargs{:});
        parsed = [parsed; promoteDatasetAttributes(datasetName, unconsumedAttributes)];
    else
        parsed(datasetName) = data;
        parsed = [parsed; promoteDatasetAttributes(datasetName, parsedAttributes)];
    end
end

function [consumable, nonConsumable] = splitAttributes(attributes, consumableNames)
    attributeNames = keys(attributes);
    isConsumable = ismember(attributeNames, consumableNames);
    
    consumable = buildSubmap(attributes, attributeNames(isConsumable));
    nonConsumable = buildSubmap(attributes, attributeNames(~isConsumable));
    
    function submap = buildSubmap(sourceMap, selectedKeys)
        if isempty(selectedKeys)
            submap = containers.Map();
        else
            submap = containers.Map(selectedKeys, values(sourceMap, selectedKeys), 'UniformValues', false);
        end
    end
end

function promotedAttributes = promoteDatasetAttributes(datasetName, attributes)
    promotedAttributes = containers.Map;

    attributeNames = keys(attributes);
    if isempty(attributeNames)
        return;
    end

    promotedAttributeNames = strcat(datasetName, '_', attributeNames);
    attributeValues = values(attributes, attributeNames);
    promotedAttributes = containers.Map(promotedAttributeNames, attributeValues);
end

function promotedFields = filterPromotedFieldsForContainer(containerTypeName, datasetName, availableFields)
    metaClass = meta.class.fromName(containerTypeName);
    if isempty(metaClass)
        promotedFields = availableFields;
        return;
    end

    containerPropertyNames = {metaClass.PropertyList.Name};
    prefixedFieldNames = strcat(datasetName, '_', availableFields);
    promotedFields = availableFields(ismember(prefixedFieldNames, containerPropertyNames));
end
