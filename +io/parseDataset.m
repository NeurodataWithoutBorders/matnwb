function parsed = parseDataset(filename, info, fullpath, blacklist)
% parseDataset - Parse an HDF5 dataset into a containers.Map representation.
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
%  - parsed    - containers.Map containing the parsed dataset representation.
%
%      Keys:
%        <dataset name>
%            Always present. Maps to the parsed dataset value.
%
%        <dataset name>_<attribute name>
%            Present only for untyped datasets when dataset
%            attributes are promoted into the output map.
%
%      Values:
%        For untyped datasets:
%            parsed(<dataset name>) contains the parsed dataset
%            value, and parsed(<dataset name>_<attribute name>)
%            contains each promoted attribute value.
%
%        For typed datasets:
%            parsed(<dataset name>) contains the typed parsed
%            object created from the parsed dataset attributes and
%            the dataset value stored under the 'data' property.
%
% Notes:
%  - HDF5 reference datasets are fully read and resolved.
%  - Scalar datasets are read eagerly and postprocessed according to their
%    datatype.
%  - Non-scalar datasets may be represented lazily using DataPipe or
%    DataStub when appropriate.
%  - For typed datasets, attributes are incorporated into the typed object
%    and are not separately promoted into the output map.

    % Initialize output
    parsed = containers.Map;

    datasetName = info.Name;

    % Parse dataset attributes
    [datasetAttributes, typeInfo] = io.parseAttributes(filename, info.Attributes, fullpath, blacklist);

    % Check if dataset is typed
    datasetTypeName = typeInfo.typename;
    isTypedDataset = ~isempty(datasetTypeName);

    % Open an HDF5 dataset handle for reading the dataset value
    fid = H5F.open(filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
    did = H5D.open(fid, fullpath);
    h5CleanupObj = onCleanup(...
        @() runOrderedCleanup({@() H5D.close(did), @()H5F.close(fid)}));

    % Read and postprocess the dataset value, or create a lazy data proxy 
    % when appropriate
    datatype = info.Datatype;
    dataspace = info.Dataspace;
    if strcmp(datatype.Class, 'H5T_REFERENCE')
        % Load all H5T references. This is required unfortunately also a 
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
                        datasetName, length(datatype.Type.Member));
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
            matlabDataType = io.internal.h5.datatype.datatypeInfoToMatlabType(datatype, datasetName);
            data = types.untyped.DataStub(filename, fullpath, dataspace.Size, matlabDataType);
        end
        H5T.close(tid);
        H5P.close(pid);
        H5S.close(sid);
    end
    clear h5CleanupObj

    if isTypedDataset
        datasetPropertyMap = datasetAttributes;
        datasetPropertyMap('data') = data;
        kwargs = io.map2kwargs(datasetPropertyMap);
        parsed(datasetName) = io.createParsedType(fullpath, datasetTypeName, kwargs{:});
    else
        attributeNames = keys(datasetAttributes);
        if ~isempty(attributeNames)
            promotedAttributeNames = strcat(datasetName, '_', attributeNames);
            parsed = [parsed; containers.Map(promotedAttributeNames, datasetAttributes.values(attributeNames))];
        end
        parsed(datasetName) = data;
    end
end

function runOrderedCleanup(cleanupFns)
    for i = 1:numel(cleanupFns)
        try
            cleanupFns{i}();
        catch
            % silently pass
        end
    end
end
