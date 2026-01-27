function datasetValue = processDatasetInfo(obj, datasetInfo, datasetPath)
    
    %disp('here: process dataset info')

    datatype = datasetInfo.Datatype;
    dataspace = datasetInfo.Dataspace;

    % HDF5-specific logic
    if ~isempty(obj.fileId)
        fid = obj.fileId;
    else
        fid = H5F.open(obj.Filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
    end
    if ~obj.isFileOpen()
        keyboard
    end
    did = H5D.open(fid, datasetPath);
    
    % loading h5t references are required
    % unfortunately also a bottleneck
    if strcmp(datatype.Class, 'H5T_REFERENCE')
        tid = H5D.get_type(did);
        datasetValue = io.parseReference(did, tid, H5D.read(did));
        H5T.close(tid);
    elseif ~strcmp(dataspace.Type, 'simple')
        datasetValue = H5D.read(did);

        switch datatype.Class
            case 'H5T_STRING'
                if verLessThan('MATLAB', '9.8')
                    % MATLAB 2020a fixed string support for HDF5, making
                    % reading strings "consistent" with regular use.
                    datasetValue = datasetValue .';
                end
                datadim = size(datasetValue);
                if datadim(1) > 1
                    %multidimensional strings should become cellstr
                    datasetValue = strtrim(mat2cell(datasetValue, ones(datadim(1), 1), datadim(2)));
                end
            case 'H5T_ENUM'
                if io.isBool(datatype.Type)
                    datasetValue = io.internal.h5.postprocess.toLogical(datasetValue);
´                else
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
    else
        sid = H5D.get_space(did);
        pid = H5D.get_create_plist(did);
        isChunked = H5P.get_layout(pid) == H5ML.get_constant_value('H5D_CHUNKED');

        tid = H5D.get_type(did);
        class_id = H5T.get_class(tid);
        isNumeric = class_id == H5ML.get_constant_value('H5T_INTEGER')...
            || class_id == H5ML.get_constant_value('H5T_FLOAT');
        if isChunked && isNumeric
            datasetValue = types.untyped.DataPipe('filename', obj.Filename, 'path', datasetPath);
        elseif any(dataspace.Size == 0)
            datasetValue = [];
        else
            matlabDataType = io.internal.h5.datatype.datatypeInfoToMatlabType(datatype);
            datasetValue = types.untyped.DataStub(obj.Filename, datasetPath, dataspace.Size, matlabDataType);
        end
        H5T.close(tid);
        H5P.close(pid);
        H5S.close(sid);
    end
    
    H5D.close(did);
    %H5F.close(fid);
end
