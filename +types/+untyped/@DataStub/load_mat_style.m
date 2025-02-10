function data = load_mat_style(obj, varargin)
    % LOAD_MAT_STYLE load data in matlab index format.
    % LOAD_MAT_STYLE(...) where each argument is an index into the dimension or ':'
    %   indicating load all of dimension. The dimension ordering is
    %   MATLAB, not HDF5 for this function.
    assert(length(varargin) <= obj.ndims, 'NWB:DataStub:Load:TooManyDimensions',...
        'Too many dimensions specified (got %d, expected %d)', length(varargin), obj.ndims);

    %% Select from Space
    dataDimensions = obj.dims;
    spaceId = obj.get_space();
    userSelection = varargin;

    selectionErrorId = 'NWB:DataStub:Load:InvalidSelection';
    for iDimension = 1:min(obj.ndims, length(userSelection))
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
        readSpaceId = H5S.copy(spaceId);
        H5S.select_none(readSpaceId);
        H5S.select_elements(readSpaceId, 'H5S_SELECT_SET', ...
            cell2mat(flipud(points)) - 1);
        memorySpaceId = H5S.create_simple(length(selectionDimensions), ...
            selectionDimensions, selectionDimensions);
    else
        % multidimensional index selection
        shapes = io.space.segmentSelection(userSelection, dataDimensions);
        [readSpaceId, memorySpaceId] = io.space.getReadSpace(shapes, spaceId);
    end
    H5S.close(spaceId);

    %% Read Data
    fileId = H5F.open(obj.filename);
    datasetId = H5D.open(fileId, obj.path);
    data = H5D.read(datasetId, 'H5ML_DEFAULT', memorySpaceId, readSpaceId, 'H5P_DEFAULT');

    %% Retype Data
    data = hdf2mat(datasetId, data);
    H5D.close(datasetId);
    H5F.close(fileId);
    H5S.close(memorySpaceId);
    
    %% Reshape Data
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

function data = hdf2mat(datasetId, data)
    typeId = H5D.get_type(datasetId);
    matlabType = io.getMatType(typeId);
    switch matlabType
        case 'logical'
            data = logical(data);
        case {'types.untyped.ObjectView', 'types.untyped.RegionView'}
            data = io.parseReference(datasetId, typeId, data);
        case 'table'
            data = io.parseCompound(datasetId, data);
        otherwise
            % no-op
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
        % dangling ':' where leftover dimensions are folded into
        % the last selection.
        selectedDimensionIndex = length(userSelection);
        expectedSize = [expectedSize(1:(selectedDimensionIndex-1)),...
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
