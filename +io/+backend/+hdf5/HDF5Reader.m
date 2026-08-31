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
            version = util.getSchemaVersion(obj.Filename);
        end

        function specLocation = getEmbeddedSpecLocation(obj)
            specLocation = io.spec.getEmbeddedSpecLocation(obj.Filename);
        end

        function node = readRootInfo(obj)
            node = h5info(obj.Filename);
        end

        function tf = isReferenceDataset(~, datasetInfo)
            tf = strcmp(datasetInfo.Datatype.Class, 'H5T_REFERENCE');
        end

        function base = getExternalLinkBase(obj)
            % HDF5 resolves a relative external-link target against the
            % directory containing the linking file. The directory is
            % returned as an absolute path so a link dereferenced after
            % the working directory has changed still resolves correctly.
            [isResolved, fileInfo] = fileattrib(char(obj.Filename));
            assert(isResolved, ...
                'NWB:Backend:Reader:FileNotFound', ...
                'Could not resolve the location of `%s`.', obj.Filename);
            base = string(fileparts(fileInfo.Name));
        end

        function linkInfo = readLinkInfo(obj, linkPath)
            arguments
                obj
                linkPath (1,1) string
            end
            propertyListId = 'H5P_DEFAULT';
            fileId = H5F.open(obj.Filename, 'H5F_ACC_RDONLY', propertyListId);
            fileCleanup = onCleanup(@() H5F.close(fileId));

            rawInfo = H5L.get_info(fileId, char(linkPath), propertyListId);
            isExternal = rawInfo.type == H5ML.get_constant_value('H5L_TYPE_EXTERNAL');
            isSoft = rawInfo.type == H5ML.get_constant_value('H5L_TYPE_SOFT');
            assert(isExternal || isSoft, ...
                'NWB:Backend:Reader:UnsupportedLinkType', ...
                'The node at "%s" in "%s" is not a soft or external link.', ...
                linkPath, obj.Filename);

            % H5L.get_val returns {targetPath} for a soft link and
            % {targetFilename, targetPath} for an external one.
            rawValue = H5L.get_val(fileId, char(linkPath), propertyListId);
            if isExternal
                linkInfo = struct('type', "external link", ...
                    'targetFilename', string(rawValue{1}), ...
                    'targetPath', string(rawValue{2}));
            else
                linkInfo = struct('type', "soft link", ...
                    'targetFilename', "", ...
                    'targetPath', string(rawValue{1}));
            end
        end

        function node = readNodeInfo(obj, nodePath)
            arguments
                obj
                nodePath (1,1) string
            end
            node = h5info(obj.Filename, char(nodePath));
        end

        function attributeValue = readAttributeValue(obj, attributeInfo, context)
            switch attributeInfo.Datatype.Class % Normalize/postprocess some HDF5 classes
                case 'H5T_STRING'
                    % H5 String type attributes are loaded differently in releases 
                    % prior to MATLAB R2020a. For details, see:
                    % https://se.mathworks.com/help/matlab/ref/h5readatt.html
                    attributeValue = attributeInfo.Value;
                    if verLessThan('matlab', '9.8') % MATLAB < R2020a
                        if iscell(attributeValue)
                            if isempty(attributeValue)
                                attributeValue = '';
                            elseif isscalar(attributeValue)
                                attributeValue = attributeValue{1};
                            else
                                % keep attributeValue as is
                            end
                        end
                    end
                case 'H5T_REFERENCE'
                    fid = H5F.open(obj.Filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
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

        function datasetValue = readDatasetValue(obj, datasetInfo, datasetPath)
            % Open an HDF5 dataset handle for reading the dataset value
            fid = H5F.open(obj.Filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
            fidCleanup = onCleanup(@() H5F.close(fid));

            did = H5D.open(fid, datasetPath);
            didCleanup = onCleanup(@() H5D.close(did));

            % Read and postprocess the dataset value, or create a lazy data proxy
            % when appropriate
            datatype = datasetInfo.Datatype;
            dataspace = datasetInfo.Dataspace;
            if obj.isReferenceDataset(datasetInfo)
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
                            % multidimensional strings should become cellstr
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
                isNumeric = classId == H5ML.get_constant_value('H5T_INTEGER') ...
                    || classId == H5ML.get_constant_value('H5T_FLOAT');
                % A compound dataset is stubbed even when it holds no rows.
                % Its member names and types are part of its structure, and
                % collapsing it to [] would drop them along with the evidence
                % that the dataset exists at all.
                isCompound = classId == H5ML.get_constant_value('H5T_COMPOUND');
                if isChunked && isNumeric
                    datasetValue = types.untyped.DataPipe('filename', obj.Filename, 'path', datasetPath);
                elseif any(dataspace.Size == 0) && ~isCompound
                    datasetValue = [];
                else
                    matlabDataType = io.internal.h5.datatype.datatypeInfoToMatlabType(datatype, datasetInfo.Name);
                    lazyArray = io.backend.hdf5.HDF5LazyArray(...
                        obj.Filename, datasetPath, dataspace.Size, matlabDataType);
                    datasetValue = types.untyped.DataStub(...
                        obj.Filename, datasetPath, [], [], lazyArray);
                end
                H5T.close(tid);
                H5P.close(pid);
                H5S.close(sid);
            end
        end
    end
end
