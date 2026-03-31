function parsed = parseDataset(filename, datasetInfo, datasetPath, blacklist)
% parseDataset - Read an HDF5 dataset and return it as named map entries.
%
% Syntax:
%  parsed = io.parseDataset(filename, datasetInfo, datasetPath, blacklist) parses the
%  dataset identified by FULLPATH in the HDF5 file FILENAME using metadata
%  from INFO.
%
% Input arguments:
%  - filename  - Path to the HDF5 file.
%  - datasetInfo - Dataset metadata structure, typically obtained from h5info.
%  - datasetPath - Full HDF5 path to the dataset.
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
        datasetInfo struct
        datasetPath (1,:) char
        blacklist struct = struct('attributes', {{}}, 'groups', {{}})
    end

    [parsedAttributes, typeInfo] = ...
        io.parseAttributes(filename, datasetInfo.Attributes, datasetPath, blacklist);

    datasetTypeName = typeInfo.typename;
    isTypedDataset = ~isempty(datasetTypeName);

    % Open an HDF5 dataset handle for reading the dataset value
    fid = H5F.open(filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
    fidCleanup = onCleanup(@() H5F.close(fid));
    
    did = H5D.open(fid, datasetPath);
    didCleanup = onCleanup(@() H5D.close(did));
    
    % Read and postprocess the dataset value, or create a lazy data proxy 
    % when appropriate
    datatype = datasetInfo.Datatype;
    dataspace = datasetInfo.Dataspace;
    if strcmp(datatype.Class, 'H5T_REFERENCE')
        % Load all H5T references. This is required, unfortunately also a 
        % bottleneck
        tid = H5D.get_type(did);
        datasetValue = io.parseReference(did, tid, H5D.read(did));
        H5T.close(tid);
    elseif strcmp(dataspace.Type, 'scalar')
        datasetValue = H5D.read(did);

        switch datatype.Class
            case 'H5T_STRING'
                if verLessThan('MATLAB', '9.8')
                    % MATLAB 2020a fixed string support for HDF5, making
                    % reading strings "consistent" with regular use.
                    datasetValue = datasetValue .';
                end
                dataDims = size(datasetValue);
                if dataDims(1) > 1
                    %multidimensional strings should become cellstr
                    datasetValue = strtrim(mat2cell(datasetValue, ones(dataDims(1), 1), dataDims(2)));
                end
            case 'H5T_ENUM'
                if io.isBool(datatype.Type)
                    datasetValue = io.internal.h5.postprocess.toLogical(datasetValue);
                else
                    warning('NWB:Dataset:UnknownEnum', ...
                        ['Encountered unknown enum under field `%s` with %d members. ' ...
                        'Will be read as cell array of characters.'], ...
                        datasetInfo.Name, length(datatype.Type.Member));
                    datasetValue = io.internal.h5.postprocess.toEnumCellStr(datasetValue, datatype.Type);
                end
            case 'H5T_COMPOUND'
                isScalar = true;
                datasetValue = io.parseCompound(did, datasetValue, isScalar);
        end
    else % non scalar
        sid = H5D.get_space(did);
        pid = H5D.get_create_plist(did);
        isChunked = H5P.get_layout(pid) == H5ML.get_constant_value('H5D_CHUNKED');

        tid = H5D.get_type(did);
        classId = H5T.get_class(tid);
        isNumeric = classId == H5ML.get_constant_value('H5T_INTEGER')...
            || classId == H5ML.get_constant_value('H5T_FLOAT');
        if isChunked && isNumeric
            datasetValue = types.untyped.DataPipe('filename', filename, 'path', datasetPath);
        elseif any(dataspace.Size == 0)
            datasetValue = [];
        else
            matlabDataType = io.internal.h5.datatype.datatypeInfoToMatlabType(datatype, datasetInfo.Name);
            datasetValue = types.untyped.DataStub(filename, datasetPath, dataspace.Size, matlabDataType);
        end
        H5T.close(tid);
        H5P.close(pid);
        H5S.close(sid);
    end

    % Prepare output
    datasetName = datasetInfo.Name;
    parsed = containers.Map;

    if isTypedDataset
        [typeProperties, unconsumedAttributes] = ...
            splitAttributes(parsedAttributes, properties(datasetTypeName));
        typeProperties('data') = datasetValue;
        kwargs = io.map2kwargs(typeProperties);
        parsed(datasetName) = io.createParsedType(datasetPath, datasetTypeName, kwargs{:});
        parsed = [parsed; promoteDatasetAttributes(datasetName, unconsumedAttributes)];
    else
        parsed(datasetName) = datasetValue;
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
