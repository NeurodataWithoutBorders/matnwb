function data = load_mat_style(obj, varargin)
    % LOAD_MAT_STYLE load data in matlab index format.
    % LOAD_MAT_STYLE(...) where each argument is an index into the dimension or ':'
    %   indicating load all of dimension. The dimension ordering is
    %   MATLAB, not HDF5 for this function.
    assert(length(varargin) <= obj.ndims, 'NWB:DataStub:Load:TooManyDimensions',...
        'Too many dimensions specified (got %d, expected %d)', length(varargin), obj.ndims);
    dimensions = obj.dims;
    spaceId = obj.get_space();
    userSelection = varargin;
    if isscalar(userSelection) && ~ischar(userSelection{1})
        % linear index into the fast dimension.
        orderedSelection = unique(userSelection{1});

        if iscolumn(orderedSelection)
            selectionDimensions = length(orderedSelection);
            orderedSelection = orderedSelection .';
        else
            selectionDimensions = fliplr(size(orderedSelection));
        end

        points = cell(length(dimensions), 1);
        [points{:}] = ind2sub(dimensions, orderedSelection);
        readSpaceId = H5S.copy(spaceId);
        H5S.select_none(readSpaceId);
        H5S.select_elements(readSpaceId, 'H5S_SELECT_SET', ...
            cell2mat(flipud(points)) - 1);
        memorySpaceId = H5S.create_simple(length(selectionDimensions), ...
            selectionDimensions, selectionDimensions);
    else
        % multidimensional index selection
        shapes = io.space.segmentSelection(userSelection, dimensions);
        [readSpaceId, memorySpaceId] = io.space.getReadSpace(shapes, spaceId);
    end
    H5S.close(spaceId);

    % read data.
    fileId = H5F.open(obj.filename);
    datasetId = H5D.open(fileId, obj.path);
    data = H5D.read(datasetId, 'H5ML_DEFAULT', memorySpaceId, readSpaceId, 'H5P_DEFAULT');
    H5D.close(datasetId);
    H5F.close(fileId);
    H5S.close(memorySpaceId);

    expectedSize = getExpectedSize();
    userSelection = varargin;
    openSelectionIndices = find(cellfun('isclass', userSelection, 'char'));
    for iIndex = 1:length(openSelectionIndices)
        % for open selection ':', select the entire range of that dimension.
        userSelection{iIndex} = 1:dimensions(iIndex);
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

        % convert int8 values to logical.
        if strcmp(obj.dataType, 'logical')
            data = logical(data);
        end
    end

    function expectedSize = getExpectedSize(dimensions, userSelection)
        expectedSize = dimensions;
        for i = 1:length(varargin)
            if ~ischar(varargin{i})
                expectedSize(i) = length(varargin{i});
            end
        end

        if ischar(varargin{end})
            % dangling ':' where leftover dimensions are folded into
            % the last selection.
            selectedDimensionIndex = length(varargin);
            expectedSize = [expectedSize(1:(selectedDimensionIndex-1)),...
                prod(dimensions(selectedDimensionIndex:end))];
        else
            expectedSize = expectedSize(1:length(varargin));
        end

        if isscalar(varargin) && isscalar(expectedSize)
            % very special case where shape of the scalar indices determine the
            % shape of the output data for some reason.
            if 1 < sum(1 < dimensions) % is multi-dimensional data
                if ~ischar(varargin{1}) && isrow(varargin{1})
                    expectedSize = [1 expectedSize];
                else
                    expectedSize = [expectedSize 1];
                end
            else
                if dimensions(1) == 1 % probably a row
                    expectedSize = [1 expectedSize];
                else % column
                    expectedSize = [expectedSize 1];
                end
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