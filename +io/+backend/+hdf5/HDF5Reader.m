classdef HDF5Reader < io.backend.base.Reader
    % HDF5Reader - HDF5 implementation of the backend reader interface.
    %
    % This reader is intentionally thin and delegates to the existing HDF5
    % utility functions used by matnwb today.

    methods
        function obj = HDF5Reader(filename)
            obj@io.backend.base.Reader(filename);
        end

        function version = getSchemaVersion(obj)
            version = util.getSchemaVersion(obj.filename);
        end

        function specLocation = getEmbeddedSpecLocation(obj)
            specLocation = io.spec.getEmbeddedSpecLocation(obj.filename);
        end

        function node = readRoot(obj)
            node = h5info(obj.filename);
        end

        function node = readNode(obj, nodePath)
            arguments
                obj
                nodePath (1,1) string
            end
            node = h5info(obj.filename, char(nodePath));
        end

        function attributeValue = processAttributeInfo(obj, attributeInfo, context)
            switch attributeInfo.Datatype.Class
                case 'H5T_STRING'
                    attributeValue = attributeInfo.Value;
                    if verLessThan('matlab', '9.8')
                        if iscell(attributeValue)
                            if isempty(attributeValue)
                                attributeValue = '';
                            elseif isscalar(attributeValue)
                                attributeValue = attributeValue{1};
                            end
                        end
                    end
                case 'H5T_REFERENCE'
                    fid = H5F.open(obj.filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
                    aid = H5A.open_by_name(fid, context, attributeInfo.Name);
                    tid = H5A.get_type(aid);
                    attributeValue = io.parseReference(aid, tid, attributeInfo.Value);
                    H5T.close(tid);
                    H5A.close(aid);
                    H5F.close(fid);
                case 'H5T_ENUM'
                    if io.isBool(attributeInfo.Datatype.Type)
                        attributeValue = io.internal.h5.postprocess.toLogical(attributeInfo.Value);
                    else
                        warning('NWB:Attribute:UnknownEnum', ...
                            ['Encountered unknown enum under field `%s` with %d members. ' ...
                            'Will be read as cell array of characters.'], ...
                            attributeInfo.Name, length(attributeInfo.Datatype.Type.Member));
                        attributeValue = io.internal.h5.postprocess.toEnumCellStr( ...
                            attributeInfo.Value, attributeInfo.Datatype.Type);
                    end
                otherwise
                    attributeValue = attributeInfo.Value;
            end
        end

        function datasetValue = processDatasetInfo(obj, datasetInfo, datasetPath)
            fid = H5F.open(obj.filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
            did = H5D.open(fid, datasetPath);
            datatype = datasetInfo.Datatype;
            dataspace = datasetInfo.Dataspace;

            if strcmp(datatype.Class, 'H5T_REFERENCE')
                tid = H5D.get_type(did);
                datasetValue = io.parseReference(did, tid, H5D.read(did));
                H5T.close(tid);
            elseif ~strcmp(dataspace.Type, 'simple')
                datasetValue = H5D.read(did);

                switch datatype.Class
                    case 'H5T_STRING'
                        if verLessThan('MATLAB', '9.8')
                            datasetValue = datasetValue.';
                        end
                        dataDims = size(datasetValue);
                        if dataDims(1) > 1
                            datasetValue = strtrim(mat2cell( ...
                                datasetValue, ones(dataDims(1), 1), dataDims(2)));
                        end
                    case 'H5T_ENUM'
                        if io.isBool(datatype.Type)
                            datasetValue = io.internal.h5.postprocess.toLogical(datasetValue);
                        else
                            warning('NWB:Dataset:UnknownEnum', ...
                                ['Encountered unknown enum under field `%s` with %d members. ' ...
                                'Will be read as cell array of characters.'], ...
                                datasetInfo.Name, length(datatype.Type.Member));
                            datasetValue = io.internal.h5.postprocess.toEnumCellStr( ...
                                datasetValue, datatype.Type);
                        end
                    case 'H5T_COMPOUND'
                        datasetValue = io.parseCompound(did, datasetValue, true);
                end
            else
                sid = H5D.get_space(did);
                pid = H5D.get_create_plist(did);
                isChunked = H5P.get_layout(pid) == H5ML.get_constant_value('H5D_CHUNKED');

                tid = H5D.get_type(did);
                classId = H5T.get_class(tid);
                isNumeric = classId == H5ML.get_constant_value('H5T_INTEGER') ...
                    || classId == H5ML.get_constant_value('H5T_FLOAT');
                if isChunked && isNumeric
                    datasetValue = types.untyped.DataPipe('filename', obj.filename, 'path', datasetPath);
                elseif any(dataspace.Size == 0)
                    datasetValue = [];
                else
                    matlabDataType = io.internal.h5.datatype.datatypeInfoToMatlabType( ...
                        datatype, datasetInfo.Name);
                    datasetValue = types.untyped.DataStub( ...
                        obj.filename, datasetPath, dataspace.Size, matlabDataType);
                end
                H5T.close(tid);
                H5P.close(pid);
                H5S.close(sid);
            end

            H5D.close(did);
            H5F.close(fid);
        end
    end
end
