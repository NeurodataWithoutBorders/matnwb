classdef HDF5LazyArray < io.backend.base.LazyArray
    % HDF5LazyArray - HDF5-backed lazy dataset access implementation.

    methods
        function obj = HDF5LazyArray(filename, path, dims, dataType)
            arguments
                filename (1,1) string
                path (1,1) string
                dims double = []
                dataType = []
            end
            obj@io.backend.base.LazyArray(filename, path, dims, dataType);
        end

        function refreshSizeInfo(obj)
            spaceId = obj.getSpace();
            [dims, maxDims] = io.space.getSize(spaceId);
            H5S.close(spaceId);
            obj.setSizeInfo(dims, maxDims);
        end

        function dataType = resolveDataType(obj)
            fileId = H5F.open(obj.filename);
            datasetId = H5D.open(fileId, obj.path);
            typeId = H5D.get_type(datasetId);

            dataType = io.getMatType(typeId);

            H5T.close(typeId);
            H5D.close(datasetId);
            H5F.close(fileId);
        end

        function data = load_h5_style(obj, varargin)
            % LOAD_H5_STYLE Read data from an HDF5 dataset.
            assert(length(varargin) ~= 1, 'NWB:DataStub:InvalidNumArguments', ...
                'calling load_h5_style with a single space id is no longer supported.');

            data = h5read(obj.filename, obj.path, varargin{:});

            if isstruct(data)
                % Compound types require consistent post-processing with
                % the rest of the HDF5 read path.
                fileId = H5F.open(obj.filename);
                datasetId = H5D.open(fileId, obj.path);
                fileSpaceId = H5D.get_space(datasetId);
                data = H5D.read(datasetId, 'H5ML_DEFAULT', fileSpaceId, fileSpaceId, ...
                    'H5P_DEFAULT');
                data = io.parseCompound(datasetId, data);
                H5S.close(fileSpaceId);
                H5D.close(datasetId);
                H5F.close(fileId);
            else
                assert(~isstruct(obj.dataType), ...
                    'NWB:DataStub:InconsistentCompoundType', ...
                    ['DataStub has compound type descriptor, but loaded data is ' ...
                    'not a struct. This indicates a file corruption or type ' ...
                    'mismatch. Expected compound data for path: %s'], obj.path);

                switch obj.dataType
                    case 'char'
                        if iscellstr(data) && isscalar(data)
                            data = data{1};
                        elseif isstring(data)
                            data = convertStringsToChars(data);
                        end
                    case 'logical'
                        data = io.internal.h5.postprocess.toLogical(data);
                end
            end
        end

        function data = load_mat_style(obj, varargin)
            % LOAD_MAT_STYLE load data in matlab index format.
            % LOAD_MAT_STYLE(...) where each argument is an index into the
            % dimension or ':' indicating load all of dimension. The
            % dimension ordering is MATLAB, not HDF5 for this function.
            assert(length(varargin) <= length(obj.dims), 'NWB:DataStub:Load:TooManyDimensions', ...
                'Too many dimensions specified (got %d, expected %d)', ...
                length(varargin), length(obj.dims));

            dataDimensions = obj.dims;
            spaceId = obj.getSpace();
            userSelection = varargin;

            selectionErrorId = 'NWB:DataStub:Load:InvalidSelection';
            for iDimension = 1:min(length(obj.dims), length(userSelection))
                selection = userSelection{iDimension};
                if ischar(selection)
                    continue;
                end
                assert(all(isreal(selection) & isfinite(selection) & selection > 0 ...
                    & selection == floor(selection)), ...
                    selectionErrorId, ...
                    'DataStub indices for dimension %u must be positive integer values', ...
                    iDimension);

                if iDimension == length(userSelection)
                    dimensionSize = prod(dataDimensions(iDimension:end));
                else
                    dimensionSize = dataDimensions(iDimension);
                end
                assert(all(dimensionSize >= selection), ...
                    selectionErrorId, ...
                    ['DataStub indices for dimension %u must be less than or equal to ' ...
                    'dimension size %u'], ...
                    iDimension, dimensionSize);
            end

            if isscalar(userSelection) && isempty(userSelection{1})
                data = obj.load_mat_style(1);
                data = getEmptyRepresentation(data);
                return
            elseif isscalar(userSelection) && ~ischar(userSelection{1})
                orderedSelection = unique(userSelection{1});

                if iscolumn(orderedSelection)
                    selectionDimensions = length(orderedSelection);
                    orderedSelection = orderedSelection.';
                else
                    selectionDimensions = fliplr(size(orderedSelection));
                end

                points = cell(length(dataDimensions), 1);

                if isscalar(dataDimensions)
                    % MATLAB R2024b requires size vectors with at least two
                    % elements when used with ind2sub.
                    dataDimensions = [dataDimensions, 1];
                end

                [points{:}] = ind2sub(dataDimensions, orderedSelection);
                readSpaceId = H5S.copy(spaceId);
                H5S.select_none(readSpaceId);
                H5S.select_elements(readSpaceId, 'H5S_SELECT_SET', ...
                    cell2mat(flipud(points)) - 1);
                memorySpaceId = H5S.create_simple(length(selectionDimensions), ...
                    selectionDimensions, selectionDimensions);
            else
                shapes = io.space.segmentSelection(userSelection, dataDimensions);
                [readSpaceId, memorySpaceId] = io.space.getReadSpace(shapes, spaceId);
            end
            H5S.close(spaceId);

            fileId = H5F.open(obj.filename);
            datasetId = H5D.open(fileId, obj.path);
            data = H5D.read(datasetId, 'H5ML_DEFAULT', memorySpaceId, readSpaceId, ...
                'H5P_DEFAULT');

            data = hdf2mat(datasetId, data);
            H5D.close(datasetId);
            H5F.close(fileId);
            H5S.close(memorySpaceId);

            expectedSize = getExpectedSize(dataDimensions, userSelection);
            openSelectionIndices = find(cellfun('isclass', userSelection, 'char'));
            for iDimension = 1:length(openSelectionIndices)
                userSelection{iDimension} = 1:dataDimensions(iDimension);
            end

            if isstruct(data)
                fieldNames = fieldnames(data);
                for iField = 1:length(fieldNames)
                    name = fieldNames{iField};
                    data.(name) = reshape( ...
                        reorderLoadedData(data.(name), userSelection), expectedSize);
                end
                data = struct2table(data);
            else
                data = reshape(reorderLoadedData(data, userSelection), expectedSize);
            end
        end
    end

    methods (Access = private)
        function spaceId = getSpace(obj)
            fileId = H5F.open(obj.filename);
            datasetId = H5D.open(fileId, obj.path);
            spaceId = H5D.get_space(datasetId);
            H5D.close(datasetId);
            H5F.close(fileId);
        end
    end
end

function data = hdf2mat(datasetId, data)
    typeId = H5D.get_type(datasetId);

    if H5T.get_class(typeId) == H5ML.get_constant_value('H5T_COMPOUND')
        data = io.parseCompound(datasetId, data);
    elseif H5T.get_class(typeId) == H5ML.get_constant_value('H5T_ENUM')
        if io.isBool(typeId)
            data = io.internal.h5.postprocess.toLogical(data);
        else
            data = io.internal.h5.postprocess.toEnumCellStr(data, typeId);
        end
    else
        matlabType = io.getMatType(typeId);
        switch matlabType
            case {'types.untyped.ObjectView', 'types.untyped.RegionView'}
                data = io.parseReference(datasetId, typeId, data);
            otherwise
                % no-op
        end
    end

    H5T.close(typeId);
end

function expectedSize = getExpectedSize(dataDimensions, userSelection)
    expectedSize = dataDimensions;
    for i = 1:length(userSelection)
        if ~ischar(userSelection{i})
            expectedSize(i) = length(userSelection{i});
        end
    end

    if ischar(userSelection{end})
        selectedDimensionIndex = length(userSelection);
        expectedSize = [expectedSize(1:(selectedDimensionIndex-1)), ...
            prod(dataDimensions(selectedDimensionIndex:end))];
    else
        expectedSize = expectedSize(1:length(userSelection));
    end

    if isscalar(userSelection) && isscalar(expectedSize)
        if 1 < sum(1 < dataDimensions)
            if ~ischar(userSelection{1}) && isrow(userSelection{1})
                expectedSize = [1, expectedSize];
            else
                expectedSize = [expectedSize, 1];
            end
        else
            if dataDimensions(1) == 1
                expectedSize = [1, expectedSize];
            else
                expectedSize = [expectedSize, 1];
            end
        end
    end
end

function reordered = reorderLoadedData(data, selections)
    % Dataset loading does not account for duplicate or unordered indices,
    % so we re-order after reading the unique selection.
    if isempty(data)
        reordered = data;
        return;
    end

    indexKey = cell(size(selections));
    isSelectionNormal = false(size(selections));
    for i = 1:length(indexKey)
        indexKey{i} = unique(selections{i});
        isSelectionNormal = isequal(indexKey{i}, selections{i});
    end
    if all(isSelectionNormal)
        reordered = data;
        return;
    end

    indexKeyIndexMax = cellfun('length', indexKey);
    if isscalar(indexKeyIndexMax)
        reordered = repmat(data(1), indexKeyIndexMax, 1);
    else
        reordered = repmat(data(1), indexKeyIndexMax);
    end

    indexKeyIndex = ones(size(selections));
    while true
        selectionIndex = cell(size(selections));
        for iSelection = 1:length(selections)
            selectionIndex{iSelection} = ...
                selections{iSelection} == indexKey{iSelection}(indexKeyIndex(iSelection));
        end
        indexKeyIndexArguments = num2cell(indexKeyIndex);
        reordered(selectionIndex{:}) = data(indexKeyIndexArguments{:});
        indexKeyIndexNextIndex = find(indexKeyIndexMax ~= indexKeyIndex, 1, 'last');
        if isempty(indexKeyIndexNextIndex)
            break;
        end
        indexKeyIndex(indexKeyIndexNextIndex) = ...
            indexKeyIndex(indexKeyIndexNextIndex) + 1;
        indexKeyIndex((indexKeyIndexNextIndex+1):end) = 1;
    end
end

function emptyInstance = getEmptyRepresentation(nonEmptyInstance)
    try
        emptyInstance = nonEmptyInstance;
        if istable(nonEmptyInstance)
            emptyInstance(:, :) = [];
        else
            emptyInstance(:) = [];
        end
    catch ME
        error('Failed to retrieve empty type for value of class "%s". Reason:\n%s', ...
            class(nonEmptyInstance), ME.message)
    end
end

