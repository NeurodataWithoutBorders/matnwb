function data = load_mat_style(obj, varargin)
    % LOAD_MAT_STYLE load data in matlab index format.
    % LOAD_MAT_STYLE(...) where each argument is an index into the dimension or ':'
    %   indicating load all of dimension. The dimension ordering is
    %   MATLAB, not HDF5 for this function.
    %
    %   A selection with two or more subscripts becomes one hyperslab per
    %   combination of the shapes of its dimensions (see io.space.findShapes
    %   and io.space.getReadSpace). HDF5 merges each hyperslab into the
    %   selection built so far, so the time to build a selection grows with
    %   the square of its hyperslab count. A selection with more than
    %   MaxHyperslabsPerRead hyperslabs is read in groups along the dimension
    %   with the most shapes, and the groups are joined in memory.
    assert(length(varargin) <= length(obj.dims), 'NWB:DataStub:Load:TooManyDimensions', ...
        'Too many dimensions specified (got %d, expected %d)', ...
        length(varargin), length(obj.dims));

    %% Select from Space
    dataDimensions = obj.dims;
    userSelection = varargin;

    selectionErrorId = 'NWB:DataStub:Load:InvalidSelection';
    for iDimension = 1:min(length(obj.dims), length(userSelection))
        selection = userSelection{iDimension};
        if ischar(selection)
            continue;
        end
        assert(all(isreal(selection) & isfinite(selection) & selection > 0 & selection == floor(selection)) ...
            , selectionErrorId ...
            , 'DataStub indices for dimension %u must be positive integer values' ...
            , iDimension);

        if iDimension == length(userSelection)
            dimensionSize = prod(dataDimensions(iDimension:end));
        else
            dimensionSize = dataDimensions(iDimension);
        end
        assert(all(dimensionSize >= selection) ...
            , selectionErrorId ...
            , ['DataStub indices for dimension %u must be less than or equal to ' ...
            'dimension size %u'] ...
            , iDimension, dimensionSize);
    end

    if isscalar(userSelection) && isempty(userSelection{1})
        % If userselection (indices) is empty, get the first element of this
        % DataStub and try to return an empty representation of that type.
        data = obj.load_mat_style(1);
        data = getEmptyRepresentation(data);
        return

    elseif isscalar(userSelection) && ~ischar(userSelection{1})
        % linear index into the fast dimension.
        orderedSelection = unique(userSelection{1});

        if iscolumn(orderedSelection)
            selectionDimensions = length(orderedSelection);
            orderedSelection = orderedSelection .';
        else
            selectionDimensions = fliplr(size(orderedSelection));
        end

        points = cell(length(dataDimensions), 1);

        if isscalar(dataDimensions)
            % Starting in MATLAB R2024b, the input argument for the size
            % of an array in ind2sub must be a vector of positive integers
            % with two or more elements. This fix replicates the behavior of
            % older MATLAB versions, where it was assumed that the a scalar
            % size referred to the row dimension. For scalar dimensions
            % (i.e., row or column vectors), we can still assume this
            % to be true in matnwb.
            dataDimensions = [dataDimensions, 1];
        end

        [points{:}] = ind2sub(dataDimensions, orderedSelection);
        spaceId = obj.getSpace();
        readSpaceId = H5S.copy(spaceId);
        H5S.close(spaceId);
        H5S.select_none(readSpaceId);
        H5S.select_elements(readSpaceId, 'H5S_SELECT_SET', ...
            cell2mat(flipud(points)) - 1);
        memorySpaceId = H5S.create_simple(length(selectionDimensions), ...
            selectionDimensions, selectionDimensions);
    else
        % multidimensional index selection
        shapes = io.space.segmentSelection(userSelection, dataDimensions);
        if prod(cellfun('length', shapes)) > obj.MaxHyperslabsPerRead
            data = readInGroups(obj, userSelection, dataDimensions, shapes);
            return
        end
        [readSpaceId, memorySpaceId] = getReadSpace(obj, shapes);
    end

    data = readSelection(obj, readSpaceId, memorySpaceId);
    data = reshapeLoadedData(data, dataDimensions, userSelection);
end

function data = readInGroups(obj, userSelection, dataDimensions, shapes)
    % readInGroups - Read a selection with many hyperslabs as several reads along one dimension.
    %
    % The sorted unique indices of the dimension with the most shapes are
    % split into groups of whole runs, so that each group selects at most
    % MaxHyperslabsPerRead hyperslabs together with the other dimensions.
    % Every group is read and reshaped like a whole selection and the groups
    % are joined along the split dimension in increasing order. Reading a
    % group puts the other dimensions in the requested order, so only the
    % split dimension is reordered afterwards when its subscript is unsorted
    % or has repeated indices.
    numShapes = cellfun('length', shapes);
    [~, splitDimension] = max(numShapes);
    hyperslabsPerShape = prod(numShapes)/numShapes(splitDimension);
    runsPerGroup = max(1, floor(obj.MaxHyperslabsPerRead/hyperslabsPerShape));

    indices = reshape(unique(userSelection{splitDimension}), 1, []);
    runFirst = find([true, diff(indices) > 1]);
    groupFirst = runFirst(1:runsPerGroup:end);
    groupLast = [groupFirst(2:end) - 1, numel(indices)];

    groups = cell(1, numel(groupFirst));
    for iGroup = 1:numel(groups)
        groupSelection = userSelection;
        groupSelection{splitDimension} = indices(groupFirst(iGroup):groupLast(iGroup));
        groupShapes = shapes;
        groupShapes{splitDimension} = io.space.findShapes(groupSelection{splitDimension});

        [readSpaceId, memorySpaceId] = getReadSpace(obj, groupShapes);
        groupData = readSelection(obj, readSpaceId, memorySpaceId);
        groups{iGroup} = reshapeLoadedData(groupData, dataDimensions, groupSelection);
    end
    data = cat(splitDimension, groups{:});

    [~, positions] = ismember(userSelection{splitDimension}, indices);
    positions = reshape(positions, 1, []);
    if ~isequal(positions, 1:numel(indices))
        subscripts = repmat({':'}, 1, max(ndims(data), splitDimension));
        subscripts{splitDimension} = positions;
        data = data(subscripts{:});
    end
end

function [readSpaceId, memorySpaceId] = getReadSpace(obj, shapes)
    % getReadSpace - File and memory dataspaces that select the given shapes.
    spaceId = obj.getSpace();
    [readSpaceId, memorySpaceId] = io.space.getReadSpace(shapes, spaceId);
    H5S.close(spaceId);
end

function data = readSelection(obj, readSpaceId, memorySpaceId)
    % readSelection - Read the selected elements of the dataset and convert them to MATLAB types.
    fileId = H5F.open(obj.Filename);
    datasetId = H5D.open(fileId, obj.DatasetPath);
    data = H5D.read(datasetId, 'H5ML_DEFAULT', memorySpaceId, readSpaceId, 'H5P_DEFAULT');

    data = hdf2mat(datasetId, data);
    H5D.close(datasetId);
    H5F.close(fileId);
    H5S.close(memorySpaceId);
    H5S.close(readSpaceId);
end

function data = hdf2mat(datasetId, data)
    typeId = H5D.get_type(datasetId);

    % Check if compound type
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

function data = reshapeLoadedData(data, dataDimensions, userSelection)
    % reshapeLoadedData - Put the read data in the shape and order of the selection.
    expectedSize = getExpectedSize(dataDimensions, userSelection);
    openSelectionIndices = find(cellfun('isclass', userSelection, 'char'));
    for iDimension = 1:length(openSelectionIndices)
        % for open selection ':', select the entire range of that dimension.
        userSelection{iDimension} = 1:dataDimensions(iDimension);
    end

    if isstruct(data)
        % for compound datatypes, reshape for all data in the
        % struct.
        fieldNames = fieldnames(data);
        for iField = 1:length(fieldNames)
            name = fieldNames{iField};
            data.(name) = reshape(reorderLoadedData(data.(name), userSelection), expectedSize);
        end
        data = struct2table(data);
    else
        data = reshape(reorderLoadedData(data, userSelection), expectedSize);
    end
end

function expectedSize = getExpectedSize(dataDimensions, userSelection)
    expectedSize = dataDimensions;
    for i = 1:length(userSelection)
        if ~ischar(userSelection{i})
            expectedSize(i) = length(userSelection{i});
        end
    end

    if ischar(userSelection{end})
        % dangling ':' where leftover dimensions are folded into
        % the last selection.
        selectedDimensionIndex = length(userSelection);
        expectedSize = [expectedSize(1:(selectedDimensionIndex-1)), ...
            prod(dataDimensions(selectedDimensionIndex:end))];
    else
        expectedSize = expectedSize(1:length(userSelection));
    end

    if isscalar(userSelection) && isscalar(expectedSize)
        % very special case where shape of the scalar indices determine the
        % shape of the output data for some reason.
        if 1 < sum(1 < dataDimensions) % is multi-dimensional data
            if ~ischar(userSelection{1}) && isrow(userSelection{1})
                expectedSize = [1 expectedSize];
            else
                expectedSize = [expectedSize 1];
            end
        else
            if dataDimensions(1) == 1 % probably a row
                expectedSize = [1 expectedSize];
            else % column
                expectedSize = [expectedSize 1];
            end
        end
    end
end

function reordered = reorderLoadedData(data, selections)
    % dataset loading does not account for duplicate or unordered
    % indices so we have to re-order everything here.
    % we presume data is the indexed values of a unique(ind)
    if isempty(data)
        reordered = data;
        return;
    end

    indexKey = cell(size(selections));
    isSelectionNormal = false(size(selections)); % that is, without duplicates or out of order.
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
            selectionIndex{iSelection} = selections{iSelection} == indexKey{iSelection}(indexKeyIndex(iSelection));
        end
        indexKeyIndexArguments = num2cell(indexKeyIndex);
        reordered(selectionIndex{:}) = data(indexKeyIndexArguments{:});
        indexKeyIndexNextIndex = find(indexKeyIndexMax ~= indexKeyIndex, 1, 'last');
        if isempty(indexKeyIndexNextIndex)
            break;
        end
        indexKeyIndex(indexKeyIndexNextIndex) = indexKeyIndex(indexKeyIndexNextIndex) + 1;
        indexKeyIndex((indexKeyIndexNextIndex+1):end) = 1;
    end
end

function emptyInstance = getEmptyRepresentation(nonEmptyInstance)
    try
        emptyInstance = nonEmptyInstance;
        if istable(nonEmptyInstance)
            % To make an empty table instance, we need to use row/column colon
            % indices to clear all the table's data. We want to keep the
            % original table's metadata, like variable names etc, so we clear
            % the table data instead of creating a new empty table with
            % table.empty
            emptyInstance(:, :) = [];
        else
            % All other types should support linear indexing.
            emptyInstance(:) = [];
        end
    catch ME
        error('Failed to retrieve empty type for value of class "%s". Reason:\n%s', ...
            class(nonEmptyInstance), ME.message)
    end
end
