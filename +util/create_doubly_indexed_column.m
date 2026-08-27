function [vector, index, index_index] = create_doubly_indexed_column(data, description)
%CREATE_DOUBLY_INDEXED_COLUMN creates the objects for a doubly-ragged column
%in an NWB DynamicTable (a VectorData indexed by two levels of VectorIndex).
%
%   Some NWB columns are doubly ragged: each table row contains a variable
%   number of sub-groups, and each sub-group contains a variable number of
%   fixed-length elements. The Units table 'waveforms' column is the canonical
%   example: each unit (row) has a number of spike events (sub-groups), and
%   each spike event has a waveform for each electrode (elements), where every
%   waveform has the same number of samples.
%
%   [VECTOR, INDEX, INDEX_INDEX] = CREATE_DOUBLY_INDEXED_COLUMN(DATA) returns a
%   VectorData (VECTOR) and two VectorIndex objects: INDEX has one entry per
%   sub-group and targets VECTOR; INDEX_INDEX has one entry per row and targets
%   INDEX. Assign them to a column and its '<col>_index'/'<col>_index_index'
%   properties (e.g. waveforms, waveforms_index, waveforms_index_index).
%
%   DATA is a cell array with one cell per table row. Each cell is either:
%     - a numeric array [nSubGroups x trailingDimensions] (single-element
%       shortcut): each slice along dimension 1 is one sub-group containing
%       exactly one element. This matches spike-sorted units on a single
%       electrode, where DATA{i} is that unit's [nSpikes x nSamples] waveform
%       matrix.
%     - a cell array where DATA{i}{j} is a numeric array
%       [nElements x trailingDimensions] holding the elements of sub-group j
%       (general, multi-element case).
%
%   All elements across all rows must have the same trailing dimensions. A row
%   may be empty ([] or {}) to represent a row with no sub-groups.
%
%   [VECTOR, INDEX, INDEX_INDEX] = CREATE_DOUBLY_INDEXED_COLUMN(DATA, DESCRIPTION)
%   sets the string DESCRIPTION on the returned VectorData.
%
%   Example (single electrode, 2 units with 3 and 4 spikes, 40 samples):
%     waveforms = {unit1Waveforms, unit2Waveforms}; % each [nSpikes x 40]
%     [wf, wfIdx, wfIdxIdx] = util.create_doubly_indexed_column(waveforms, 'spike waveforms');
%     units.waveforms = wf;
%     units.waveforms_index = wfIdx;
%     units.waveforms_index_index = wfIdxIdx;
%
%   See also util.create_indexed_column

    arguments
        data cell
        description (1,1) string = "no description"
    end

    numRows = numel(data);
    outerCounts = zeros(numRows, 1);    % number of sub-groups per row
    rowChunks = cell(1, numRows);       % data chunks with ragged axis last
    rowInnerCounts = cell(1, numRows);  % element count per sub-group, per row
    payloadSize = [];                   % fixed trailing dimensions, once known

    for iRow = 1:numRows
        rowData = data{iRow};
        if isnumeric(rowData) || islogical(rowData)
            [chunk, counts, payloadSize] = fromArray(rowData, payloadSize, iRow);
        elseif iscell(rowData)
            [chunk, counts, payloadSize] = fromCell(rowData, payloadSize, iRow);
        else
            error("NWB:CreateDoublyIndexedColumn:InvalidRow", ...
                "Each element of DATA must be a numeric array or a cell array. " + ...
                "Element %d is a %s.", iRow, class(rowData));
        end
        rowChunks{iRow} = chunk;
        rowInnerCounts{iRow} = counts;
        outerCounts(iRow) = numel(counts);
    end

    allData = concatenateChunks(rowChunks, payloadSize);
    innerCounts = vertcat(rowInnerCounts{:});     % one entry per sub-group

    vector = types.hdmf_common.VectorData( ...
        'description', char(description), ...
        'data', allData);

    index = types.hdmf_common.VectorIndex( ...
        'description', 'Index into the data column, one entry per sub-group', ...
        'target', types.untyped.ObjectView(vector), ...
        'data', uint64(cumsum(innerCounts)));

    index_index = types.hdmf_common.VectorIndex( ...
        'description', 'Index into the index column, one entry per row', ...
        'target', types.untyped.ObjectView(index), ...
        'data', uint64(cumsum(outerCounts)));
end

function [chunk, counts, payloadSize] = fromArray(rowData, payloadSize, iRow)
    % Shortcut form: [nSubGroups x trailingDimensions], one element per sub-group.
    if isempty(rowData)
        chunk = [];
        counts = zeros(0, 1);
        return
    end
    payloadSize = checkPayloadSize(getPayloadSize(rowData), payloadSize, iRow);
    chunk = moveFirstDimensionToLast(rowData);
    counts = ones(size(rowData, 1), 1);   % one element per sub-group
end

function [chunk, counts, payloadSize] = fromCell(rowData, payloadSize, iRow)
    % General form: rowData{j} = [nElements x trailingDimensions] for sub-group j.
    numGroups = numel(rowData);
    chunks = cell(1, numGroups);
    counts = zeros(numGroups, 1);
    for j = 1:numGroups
        element = rowData{j};
        if ~(isnumeric(element) || islogical(element))
            error("NWB:CreateDoublyIndexedColumn:InvalidElement", ...
                "DATA{%d}{%d} must be a numeric array.", iRow, j);
        end
        if ~isempty(element)
            payloadSize = checkPayloadSize(getPayloadSize(element), payloadSize, iRow);
            chunks{j} = moveFirstDimensionToLast(element);
        else
            chunks{j} = [];
        end
        counts(j) = size(element, 1);
    end
    chunk = concatenateChunks(chunks, payloadSize);
end

function payloadSize = checkPayloadSize(thisSize, payloadSize, iRow)
    if isempty(payloadSize)
        payloadSize = thisSize;
    elseif ~isequal(thisSize, payloadSize)
        error("NWB:CreateDoublyIndexedColumn:InconsistentSampleLength", ...
            "All elements must have the same trailing dimensions. " + ...
            "Expected [%s], but an element in row %d has [%s].", ...
            join(string(payloadSize), " "), iRow, join(string(thisSize), " "));
    end
end

function payloadSize = getPayloadSize(array)
    arraySize = size(array);
    payloadSize = arraySize(2:end);
end

function data = moveFirstDimensionToLast(data)
    data = permute(data, ndims(data):-1:1);
end

function data = concatenateChunks(chunks, payloadSize)
    nonEmptyChunks = chunks(~cellfun(@isempty, chunks));
    if isempty(nonEmptyChunks)
        data = [];
        return
    end
    data = cat(numel(payloadSize) + 1, nonEmptyChunks{:});
end
