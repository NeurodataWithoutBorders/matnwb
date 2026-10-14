classdef HDF5Reader < io.backend.base.Reader
    % HDF5Reader - HDF5 implementation of the backend reader interface.
    %
    % This reader is intentionally thin and delegates to the existing HDF5
    % utility functions used by matnwb today. Nodes are described from
    % h5info output; the BackendInfo of a DatasetInfo is a struct with the
    % h5info Datatype and Dataspace, and the BackendInfo of an
    % AttributeInfo is the h5info Datatype.

    methods (Static)
        function tf = canOpen(filename)
        % canOpen - Whether filename is an HDF5 file.
        %
        % H5F.is_hdf5 reads the file signature without opening the file,
        % and returns a negative value for a path that is not a file.
            arguments
                filename (1,1) string
            end
            tf = H5F.is_hdf5(char(filename)) > 0;
        end
    end

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
            node = toGroupInfo(h5info(obj.Filename));
        end

        function tf = isReferenceDataset(~, datasetInfo)
            tf = strcmp(datasetInfo.BackendInfo.Datatype.Class, 'H5T_REFERENCE');
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

        function node = readNodeInfo(obj, nodePath)
            arguments
                obj
                nodePath (1,1) string
            end
            % h5info describes a link at nodePath without following it.
            h5Info = h5info(obj.Filename, char(nodePath));
            if isfield(h5Info, 'Groups')
                node = toGroupInfo(h5Info);
            elseif isfield(h5Info, 'Datatype')
                node = toDatasetInfo(h5Info);
            else
                [~, linkName] = io.pathParts(char(nodePath));
                node = toLinkInfo(h5Info, linkName);
            end
        end

        function attributeValue = readAttributeValue(obj, attributeInfo, context)
            datatype = attributeInfo.BackendInfo;
            switch datatype.Class % Normalize/postprocess some HDF5 classes
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
                    if io.isBool(datatype.Type)
                        attributeValue = io.internal.h5.postprocess.toLogical(attributeInfo.Value);
                    else
                        warning('NWB:Attribute:UnknownEnum', ...
                            ['Encountered unknown enum under field `%s` with %d members. ' ...
                            'Will be read as cell array of characters.'], ...
                            attributeInfo.Name, length(datatype.Type.Member));
                        attributeValue = io.internal.h5.postprocess.toEnumCellStr( ...
                            attributeInfo.Value, datatype.Type);
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
            datatype = datasetInfo.BackendInfo.Datatype;
            dataspace = datasetInfo.BackendInfo.Dataspace;
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

function groupInfo = toGroupInfo(h5Group)
% toGroupInfo - Describe a group from its h5info struct, recursively.
    groups = io.backend.model.GroupInfo.empty(0, 1);
    for iGroup = numel(h5Group.Groups):-1:1
        groups(iGroup, 1) = toGroupInfo(h5Group.Groups(iGroup));
    end
    datasets = io.backend.model.DatasetInfo.empty(0, 1);
    for iDataset = numel(h5Group.Datasets):-1:1
        datasets(iDataset, 1) = toDatasetInfo(h5Group.Datasets(iDataset));
    end
    links = io.backend.model.LinkInfo.empty(0, 1);
    for iLink = numel(h5Group.Links):-1:1
        h5Link = h5Group.Links(iLink);
        links(iLink, 1) = toLinkInfo(h5Link, h5Link.Name);
    end
    groupInfo = io.backend.model.GroupInfo(h5Group.Name, Groups=groups, ...
        Datasets=datasets, Links=links, ...
        Attributes=toAttributeInfo(h5Group.Attributes));
end

function datasetInfo = toDatasetInfo(h5Dataset)
% toDatasetInfo - Describe a dataset from its h5info struct.
    backendInfo = struct( ...
        'Datatype', h5Dataset.Datatype, ...
        'Dataspace', h5Dataset.Dataspace);
    datasetInfo = io.backend.model.DatasetInfo(h5Dataset.Name, ...
        toAttributeInfo(h5Dataset.Attributes), backendInfo);
end

function linkInfo = toLinkInfo(h5Link, linkName)
% toLinkInfo - Describe a link from its h5info struct.
%
% h5info gives the target of a soft or hard link as {targetPath} and that
% of an external link as {targetFile; targetPath}. Any other link type is
% described by its type only, which io.parseGroup rejects.
    switch h5Link.Type
        case {'soft link', 'hard link'}
            linkInfo = io.backend.model.LinkInfo(linkName, h5Link.Type, ...
                h5Link.Value{1});
        case 'external link'
            linkInfo = io.backend.model.LinkInfo(linkName, h5Link.Type, ...
                h5Link.Value{2}, h5Link.Value{1});
        otherwise
            linkInfo = io.backend.model.LinkInfo(linkName, h5Link.Type);
    end
end

function attributes = toAttributeInfo(h5Attributes)
% toAttributeInfo - Describe attributes from their h5info structs.
%
% h5info gives [] for a node without attributes.
    if isempty(h5Attributes)
        attributes = io.backend.model.AttributeInfo.empty(0, 1);
    else
        attributes = io.backend.model.AttributeInfo.fromLists( ...
            {h5Attributes.Name}, {h5Attributes.Value}, {h5Attributes.Datatype});
    end
end
