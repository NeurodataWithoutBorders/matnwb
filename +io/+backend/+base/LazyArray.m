classdef LazyArray < handle
% LazyArray - Base class for backend-specific lazy dataset access.
%
% DataStub owns the public lazy dataset API exposed by MatNWB, while
% LazyArray implementations encapsulate storage-specific metadata
% discovery and indexed reads.
%
% The base class serves MATLAB-style subscripts (load_mat_style): it checks
% them, chooses how to read them, and returns the values in the order and
% shape the subscripts ask for. A backend implements two reads in its own
% storage order, readSubscripts and readPoints, and describes its storage
% by overriding isStorageOrderReversed and getBoundingBoxLimits.

    properties (SetAccess = protected)
        % Filename - The path name of a file containing the dataset
        % wrapped by this LazyArray object.
        Filename (1,1) string

        % DatasetPath - The path name of the dataset wrapped by this LazyArray
        % object relative to the root of the file.
        DatasetPath (1,1) string
    end

    properties (Dependent, SetAccess = private)
        dims
        maxDims
        dataType
    end

    properties (Access = protected)
        dims_ double = []
        maxDims_ double = []
        dataType_ = []
    end

    methods % Constructor and property getters.
        function obj = LazyArray(filename, path, dims, dataType)
            arguments
                filename (1,1) string = missing
                path (1,1) string = missing
                dims double = []
                dataType = []
            end

            obj.Filename = filename;
            obj.DatasetPath = path;

            if ~isempty(dims)
                obj.setSizeInfo(dims, obj.maxDims_);
            end
            if ~isempty(dataType)
                obj.setDataTypeInfo(dataType);
            end
        end

        function dims = get.dims(obj)
            if isempty(obj.dims_)
                obj.refreshSizeInfo();
            end
            dims = obj.dims_;
        end

        function maxDims = get.maxDims(obj)
            if isempty(obj.maxDims_)
                obj.refreshSizeInfo();
            end
            maxDims = obj.maxDims_;
        end

        function dataType = get.dataType(obj)
            if isempty(obj.dataType_)
                obj.setDataTypeInfo(obj.resolveDataType());
            end
            dataType = obj.dataType_;
        end
    end

    methods
        function data = load_mat_style(obj, varargin)
        % load_mat_style - Read a selection given as MATLAB subscripts.
        %
        % data = load_mat_style(obj, s1, ..., sN) reads the elements that
        % the subscripts select from the dataset, in MatNWB's dimension
        % order. Each subscript is ':' or a vector of positive integers,
        % in any order and with repeats. A single numeric subscript is a
        % linear index. A trailing ':' spans every remaining dimension,
        % folded into one. With no subscripts the whole dataset is read. A
        % compound dataset is returned as a table.
            dataDimensions = obj.dims;
            userSelection = varargin;
            validateSelection(userSelection, dataDimensions);

            if isempty(userSelection)
                userSelection = repmat({':'}, 1, numel(dataDimensions));
            end

            if isscalar(userSelection) && isempty(userSelection{1})
                % The class of an empty selection is the class of the
                % dataset's first element.
                data = getEmptyRepresentation(obj.load_mat_style(1));
                return
            end

            if isscalar(userSelection) && ~ischar(userSelection{1})
                data = obj.readLinearSelection(userSelection{1});
            else
                data = obj.readSubscriptSelection(userSelection);
            end

            if isstruct(data)
                data = struct2table(data);
            end
        end
    end

    methods % Should be implemented by subclasses
        function refreshSizeInfo(obj) %#ok<MANU>
        % refreshSizeInfo - Read the dataset's size and set dims and maxDims.
            io.backend.base.LazyArray.throwNotImplemented("refreshSizeInfo")
        end

        function dataType = resolveDataType(obj) %#ok<MANU>
        % resolveDataType - Read the MATLAB class of the dataset's elements.
            dataType = [];
            io.backend.base.LazyArray.throwNotImplemented("resolveDataType")
        end

        function data = load_h5_style(obj, varargin) %#ok<INUSD>
        % load_h5_style - Read a hyperslab given as start, count and stride.
            data = [];
            io.backend.base.LazyArray.throwNotImplemented("load_h5_style")
        end
    end

    methods (Access = protected) % Reads, implemented by subclasses
        function data = readSubscripts(obj, selection) %#ok<INUSD>
        % readSubscripts - Read every combination of per-dimension indices.
        %
        % Input Arguments:
        %  - selection - Cell array with one element per dataset dimension,
        %    in storage order. Each element is ':' for the whole dimension
        %    or a sorted row vector of unique positive indices, possibly
        %    empty.
        %
        % Output Arguments:
        %  - data - Array in storage order whose i-th dimension has the
        %    length of the whole dimension for ':' and numel(selection{i})
        %    otherwise. A compound dataset gives a scalar struct with one
        %    such array per field.
            data = [];
            io.backend.base.LazyArray.throwNotImplemented("readSubscripts")
        end

        function values = readPoints(obj, subscripts) %#ok<INUSD>
        % readPoints - Read single elements.
        %
        % Input Arguments:
        %  - subscripts - Matrix with one row of subscripts per element, in
        %    storage order.
        %
        % Output Arguments:
        %  - values - Column with one value per row of subscripts. A
        %    compound dataset gives a scalar struct of such columns.
            values = [];
            io.backend.base.LazyArray.throwNotImplemented("readPoints")
        end
    end

    methods (Access = protected) % Storage description, overridden by subclasses
        function tf = isStorageOrderReversed(obj) %#ok<MANU>
        % isStorageOrderReversed - Whether storage order reverses MatNWB's.
        %
        % A backend that reads arrays in row-major order, as numpy-based
        % writers store them, returns true. readSubscripts and readPoints
        % then work in that order, and the base class reverses
        % subscripts on the way in and dimensions on the way out.
            tf = false;
        end

        function [maxOverread, minElements] = getBoundingBoxLimits(obj) %#ok<MANU>
        % getBoundingBoxLimits - When a linear selection is read as a box.
        %
        % A linear selection is read with readSubscripts through the box
        % that bounds it when the box holds at most maxOverread times as
        % many elements as the selection, or at most minElements, and
        % element by element with readPoints otherwise. By default a box
        % is read only when the selection fills it.
            maxOverread = 1;
            minElements = 0;
        end
    end

    methods (Access = protected)
        function setSizeInfo(obj, dims, maxDims)
            obj.dims_ = dims;
            obj.maxDims_ = maxDims;
        end

        function setDataTypeInfo(obj, dataType)
            if isstring(dataType) || ischar(dataType)
                obj.dataType_ = char(dataType);
            else
                obj.dataType_ = dataType;
            end
        end

        function dims = toMatnwbOrder(obj, storageDims)
        % toMatnwbOrder - Dimensions in MatNWB's order from storage order.
            dims = storageDims;
            if obj.isStorageOrderReversed()
                dims = fliplr(dims);
            end
        end

        function data = readHyperslab(obj, start, count, stride)
        % readHyperslab - Read a regular hyperslab given in MatNWB's order.
        %
        % start is 1-based. A count of Inf reads to the end of its
        % dimension, and stride defaults to 1 along each dimension.
            arguments
                obj
                start (1,:) double
                count (1,:) double
                stride (1,:) double = ones(size(start))
            end
            dataDimensions = obj.dims;
            isToEnd = isinf(count);
            count(isToEnd) = floor((dataDimensions(isToEnd) - start(isToEnd)) ...
                ./ stride(isToEnd)) + 1;
            selection = cell(1, numel(start));
            for iDimension = 1:numel(start)
                selection{iDimension} = start(iDimension) ...
                    + (0:count(iDimension)-1) * stride(iDimension);
            end
            data = obj.readInMatnwbOrder(selection);
        end
    end

    methods (Access = private)
        function data = readLinearSelection(obj, linearIndices)
        % readLinearSelection - Read the elements named by linear indices.
        %
        % The unique indices are read through their bounding box or point
        % by point (see getBoundingBoxLimits), then put back in the
        % caller's order, repeats included, and shape.
            dataDimensions = obj.dims;
            rank = numel(dataDimensions);
            uniqueIndices = unique(linearIndices(:));

            subscripts = cell(1, max(rank, 2));
            % ind2sub needs two or more dimensions; a single dimension is
            % the row dimension.
            [subscripts{:}] = ind2sub([dataDimensions, 1], uniqueIndices);
            subscripts = cell2mat(subscripts(1:rank));

            lowest = min(subscripts, [], 1);
            boxSize = max(subscripts, [], 1) - lowest + 1;
            [maxOverread, minElements] = obj.getBoundingBoxLimits();
            if prod(boxSize) <= max(maxOverread * numel(uniqueIndices), minElements)
                boxSelection = arrayfun(@(first, len) first:(first + len - 1), ...
                    lowest, boxSize, 'UniformOutput', false);
                box = obj.readInMatnwbOrder(boxSelection);
                localSubscripts = num2cell(subscripts - lowest + 1, 1);
                if rank == 1
                    positionsInBox = localSubscripts{1};
                else
                    positionsInBox = sub2ind(boxSize, localSubscripts{:});
                end
                uniqueValues = applyToData(box, @(x) x(positionsInBox));
            elseif obj.isStorageOrderReversed()
                uniqueValues = obj.readPoints(fliplr(subscripts));
            else
                uniqueValues = obj.readPoints(subscripts);
            end

            [~, positions] = ismember(linearIndices, uniqueIndices);
            expectedSize = getExpectedSize(dataDimensions, {linearIndices});
            data = applyToData(uniqueValues, ...
                @(x) reshape(x(positions), expectedSize));
        end

        function data = readSubscriptSelection(obj, userSelection)
        % readSubscriptSelection - Read a selection with a subscript per dimension.
        %
        % Each dimension's indices are read once, sorted, and the result
        % is reordered to the caller's subscripts. Dimensions after the
        % last subscript are read at index 1, or whole after a trailing
        % ':'.
            dataDimensions = obj.dims;
            rank = numel(dataDimensions);
            isDanglingGroup = ischar(userSelection{end});
            selection = cell(1, rank);
            for iDimension = 1:rank
                if iDimension > numel(userSelection)
                    if isDanglingGroup
                        selection{iDimension} = ':';
                    else
                        selection{iDimension} = 1;
                    end
                elseif ischar(userSelection{iDimension})
                    selection{iDimension} = ':';
                else
                    selection{iDimension} = reshape(unique(userSelection{iDimension}), 1, []);
                end
            end
            data = obj.readInMatnwbOrder(selection);

            expectedSize = getExpectedSize(dataDimensions, userSelection);
            openSelectionIndices = reshape(find(cellfun('isclass', userSelection, 'char')), 1, []);
            for iDimension = openSelectionIndices
                % for open selection ':', select the entire range of that dimension.
                if iDimension == length(userSelection)
                    % A trailing ':' spans every remaining dimension, folded
                    % into one as in getExpectedSize.
                    userSelection{iDimension} = 1:prod(dataDimensions(iDimension:end));
                else
                    userSelection{iDimension} = 1:dataDimensions(iDimension);
                end
            end
            data = applyToData(data, ...
                @(x) reshape(reorderLoadedData(x, userSelection), expectedSize));
        end

        function data = readInMatnwbOrder(obj, selection)
        % readInMatnwbOrder - readSubscripts with selection and result in MatNWB's order.
            if ~obj.isStorageOrderReversed()
                data = obj.readSubscripts(selection);
                return
            end
            data = obj.readSubscripts(fliplr(selection));
            rank = numel(selection);
            if rank >= 2
                data = applyToData(data, @(x) permute(x, rank:-1:1));
            end
        end
    end

    methods (Static, Access = private)
        function throwNotImplemented(methodName)
            error("NWB:Backend:LazyArray:NotImplemented", ...
                "LazyArray method `%s` is not implemented.", methodName)
        end
    end
end

function validateSelection(userSelection, dataDimensions)
    assert(length(userSelection) <= length(dataDimensions), ...
        'NWB:DataStub:Load:TooManyDimensions', ...
        'Too many dimensions specified (got %d, expected %d)', ...
        length(userSelection), length(dataDimensions));

    selectionErrorId = 'NWB:DataStub:Load:InvalidSelection';
    for iDimension = 1:length(userSelection)
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
end

function data = applyToData(data, operation)
% applyToData - Apply an operation to an array, or to each field of a compound.
    if isstruct(data)
        fieldNames = fieldnames(data);
        for iField = 1:numel(fieldNames)
            name = fieldNames{iField};
            data.(name) = operation(data.(name));
        end
    else
        data = operation(data);
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
        isSelectionNormal(i) = isequal(indexKey{i}, selections{i});
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
