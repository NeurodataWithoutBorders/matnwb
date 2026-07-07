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
%     - a numeric matrix [nSubGroups x nSamples] (single-element shortcut):
%       each row is one sub-group containing exactly one element. This matches
%       spike-sorted units on a single electrode, where DATA{i} is that unit's
%       [nSpikes x nSamples] waveform matrix.
%     - a cell array where DATA{i}{j} is a numeric matrix [nElements x nSamples]
%       holding the elements of sub-group j (general, multi-element case).
%
%   All elements across all rows must have the same number of samples (columns).
%   A row may be empty ([] or {}) to represent a row with no sub-groups.
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
    rowChunks = cell(1, numRows);       % [nSamples x nElements] data per row
    rowInnerCounts = cell(1, numRows);  % element count per sub-group, per row
    sampleCount = [];                   % fixed number of samples, once known

    for iRow = 1:numRows
        rowData = data{iRow};
        if isnumeric(rowData) || islogical(rowData)
            [chunk, counts, sampleCount] = fromMatrix(rowData, sampleCount, iRow);
        elseif iscell(rowData)
            [chunk, counts, sampleCount] = fromCell(rowData, sampleCount, iRow);
        else
            error("NWB:CreateDoublyIndexedColumn:InvalidRow", ...
                "Each element of DATA must be a numeric matrix or a cell array. " + ...
                "Element %d is a %s.", iRow, class(rowData));
        end
        rowChunks{iRow} = chunk;
        rowInnerCounts{iRow} = counts;
        outerCounts(iRow) = numel(counts);
    end

    allData = [rowChunks{:}];                     % [nSamples x totalElements]
    innerCounts = vertcat(rowInnerCounts{:});     % one entry per sub-group

    vector = types.hdmf_common.VectorData( ...
        'description', description, ...
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

function [chunk, counts, sampleCount] = fromMatrix(rowData, sampleCount, iRow)
    % Shortcut form: [nSubGroups x nSamples], one element per sub-group.
    if isempty(rowData)
        chunk = [];
        counts = zeros(0, 1);
        return
    end
    sampleCount = checkSamples(size(rowData, 2), sampleCount, iRow);
    chunk = rowData.';                    % [nSamples x nSubGroups]
    counts = ones(size(rowData, 1), 1);   % one element per sub-group
end

function [chunk, counts, sampleCount] = fromCell(rowData, sampleCount, iRow)
    % General form: rowData{j} = [nElements x nSamples] for sub-group j.
    numGroups = numel(rowData);
    chunks = cell(1, numGroups);
    counts = zeros(numGroups, 1);
    for j = 1:numGroups
        element = rowData{j};
        if ~(isnumeric(element) || islogical(element)) || ~ismatrix(element)
            error("NWB:CreateDoublyIndexedColumn:InvalidElement", ...
                "DATA{%d}{%d} must be a numeric matrix.", iRow, j);
        end
        if ~isempty(element)
            sampleCount = checkSamples(size(element, 2), sampleCount, iRow);
        end
        counts(j) = size(element, 1);
        chunks{j} = element.';
    end
    chunk = [chunks{:}];
end

function sampleCount = checkSamples(thisCount, sampleCount, iRow)
    if isempty(sampleCount)
        sampleCount = thisCount;
    elseif thisCount ~= sampleCount
        error("NWB:CreateDoublyIndexedColumn:InconsistentSampleLength", ...
            "All elements must have the same number of samples (columns). " + ...
            "Expected %d, but an element in row %d has %d.", ...
            sampleCount, iRow, thisCount);
    end
end
