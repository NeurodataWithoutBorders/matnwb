function parsed = parseDataset(filename, info, fullpath, blacklist)

    %typed and untyped being container maps containing type and untyped datasets
    % the maps store information regarding information and stored data

    % Output arguments:
    %   parsed - containers.Map containing parsed representations of the
    %       dataset and its attributes.
    %
    %       Keys:
    %         - <dataset name> for the parsed dataset value
    %         - <dataset name>_<attribute name> for each parsed attribute
    %
    %       Values:
    %         - The parsed dataset value for untyped datasets
    %         - A parsed typed object for typed datasets
    %         - The parsed attribute values for promoted attributes


    % Initialize output
    parsed = containers.Map;

    % NOTE, dataset name is in path format so we need to parse that out.
    name = info.Name;

    % Parse dataset attributes
    [datasetAttributes, typeInfo] = io.parseAttributes(filename, info.Attributes, fullpath, blacklist);

    % Check if dataset is typed
    datasetType = typeInfo.typename;
    isTypedDataset = ~isempty(datasetType);

    fid = H5F.open(filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
    did = H5D.open(fid, fullpath);
    datatype = info.Datatype;
    dataspace = info.Dataspace;

    % loading h5t references are required
    % unfortunately also a bottleneck
    if strcmp(datatype.Class, 'H5T_REFERENCE')
        tid = H5D.get_type(did);
        data = io.parseReference(did, tid, H5D.read(did));
        H5T.close(tid);
    elseif ~strcmp(dataspace.Type, 'simple') % i.e scalar
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
                        name, length(datatype.Type.Member));
                    data = io.internal.h5.postprocess.toEnumCellStr(data, datatype.Type);
                end
            case 'H5T_COMPOUND'
                isScalar = true;
                data = io.parseCompound(did, data, isScalar);
        end
    else
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
            matlabDataType = io.internal.h5.datatype.datatypeInfoToMatlabType(datatype, name);
            data = types.untyped.DataStub(filename, fullpath, dataspace.Size, matlabDataType);
        end
        H5T.close(tid);
        H5P.close(pid);
        H5S.close(sid);
    end

    if isTypedDataset
        datasetPropertyMap = datasetAttributes;
        datasetPropertyMap('data') = data;
        kwargs = io.map2kwargs(datasetPropertyMap);
        parsed(name) = io.createParsedType(fullpath, datasetType, kwargs{:});
    else
        afields = keys(datasetAttributes);
        if ~isempty(afields)
            anames = strcat(name, '_', afields);
            parsed = [parsed; containers.Map(anames, datasetAttributes.values(afields))];
        end
        parsed(name) = data;
    end
    H5D.close(did);
    H5F.close(fid);
end
