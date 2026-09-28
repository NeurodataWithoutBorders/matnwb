function [data_vector, varargout] = create_indexed_column(data, description, table, options)
%CREATE_INDEXED_COLUMN creates the vector and index NWB objects for storing
%a ragged column in an NWB DynamicTable
%
%   [DATA_VECTOR, DATA_INDEX] = CREATE_INDEXED_COLUMN(DATA)
%   expects DATA as a cell array with one cell per table row, holding that
%   row's elements. Each cell is one of:
%     - a numeric or logical vector (row or column): a list of scalar
%       elements. When every row is a vector, DATA_VECTOR.data is a column
%       vector holding all elements.
%     - a numeric or logical array [elementDims x nElements]: nElements
%       elements that each have the shape elementDims, with the ragged axis
%       last, in the same orientation as the data property of any MatNWB
%       VectorData. Rows are concatenated along that last dimension, so
%       DATA_VECTOR.data is [elementDims x totalElements]. On disk the ragged
%       axis then comes first, as the schema requires.
%     - [] for a row with no elements.
%   All array rows must share elementDims. Trailing dimensions of 1 may be
%   omitted, as MATLAB omits them from size: the number of element
%   dimensions is the largest any row shows, and rows with fewer dimensions
%   are padded with ones. A row holding a single element is thus a column
%   vector [k x 1] when elements are k-sample vectors, or a [k x m] matrix
%   when elements are [k x m].
%   EXAMPLE: [data_vector, data_index] = util.create_indexed_column({[1,2,3], [1,2,3,4]})
%     data_vector.data is [1;2;3;1;2;3;4] and data_index.data is [3;7].
%   EXAMPLE: [data_vector, data_index] = util.create_indexed_column({rand(4,2), rand(4,3)})
%     data_vector.data is [4 x 5] (five 4-sample elements) and data_index.data is [2;5].
%
%   [DATA_VECTOR, DATA_INDEX] = CREATE_INDEXED_COLUMN(DATA, DESCRIPTION)
%   adds the string DESCRIPTION in the description field of the data vector
%
%   [DYNAMICTABLEREGION, DATA_INDEX] = CREATE_INDEXED_COLUMN(DATA, DESCRIPTION, TABLE)
%   If TABLE is supplied as on ObjectView of an NWB DynamicTable, a
%   DynamicTableRegion is instead output which references this table.
%   DynamicTableRegions can be indexed just like DataVectors
%
%   [DATA_VECTOR, INDEX1, ..., INDEXn] = CREATE_INDEXED_COLUMN(__, 'Depth', n)
%   builds a column with n levels of VectorIndex; n = 2 gives a doubly ragged
%   column such as Units.waveforms. INDEX1 targets DATA_VECTOR and has one
%   entry per innermost sub-group; every further index targets the one before
%   it, and INDEXn has one entry per table row. Assign them to the column and
%   its '<col>_index', '<col>_index_index', ... properties.
%
%   With 'Depth', n each cell of DATA is one of:
%     - a cell array with one entry per sub-group, each entry being a row of
%       depth n-1. For n = 2 that is a cell of [elementDims x nElements]
%       arrays, one per sub-group. Vector entries follow the array rule here,
%       not the scalar-list rule: a column vector [k x 1] is one k-sample
%       element and a row vector [1 x m] is m single-sample elements.
%     - a numeric array [elementDims x nElements x nSubGroups] (for n = 2):
%       every sub-group holds nElements elements. For Units.waveforms this is
%       [num_samples x num_electrodes x num_spike_events] per unit, which is
%       the (num_spikes, num_electrodes, num_samples) array PyNWB's
%       Units.add_unit takes with its dimensions reversed, as for any other
%       MatNWB dataset. A unit with a single spike event is then
%       [num_samples x num_electrodes], its trailing dimension of 1 omitted.
%     - a numeric matrix [k x nSubGroups] (for n = 2): every sub-group holds a
%       single k-sample element, as for spike waveforms on one electrode.
%       This shortcut is used only while no numeric row of DATA has more
%       than n dimensions. Once a row shows the full form above, a [k x m]
%       row is read as that form with its trailing dimension of 1 omitted:
%       one sub-group of m elements. The cell form is unambiguous either way.
%     - [] or {} for a row with no sub-groups, or [elementDims x 0 x nSubGroups]
%       for nSubGroups sub-groups that hold no elements.
%   EXAMPLE (waveforms of 2 units with 3 and 4 spikes on one electrode):
%     unit1 = rand(40, 3); unit2 = rand(40, 4);   % [num_samples x num_spikes]
%     [wf, wfIndex, wfIndexIndex] = util.create_indexed_column({unit1, unit2}, 'spike waveforms', 'Depth', 2);
%     units.waveforms = wf;
%     units.waveforms_index = wfIndex;
%     units.waveforms_index_index = wfIndexIndex;
%
%   See also types.hdmf_common.DynamicTable/addRaggedArray

    arguments
        data cell
        description = ''
        table = []
        options.Depth (1,1) {mustBeInteger, mustBePositive} = 1
    end

    depth = options.Depth;
    if nargout > depth + 1
        error("NWB:CreateIndexedColumn:TooManyOutputs", ...
            "A column of depth %d has %d outputs: the data vector and %d index level(s).", ...
            depth, depth + 1, depth);
    end
    if isempty(description)
        description = 'no description';
    else
        description = char(description);
    end

    [flatData, counts] = flattenRows(data, depth);

    if isempty(table)
        data_vector = types.hdmf_common.VectorData( ...
            'data', flatData, ...
            'description', description ...
        );
    else
        data_vector = types.hdmf_common.DynamicTableRegion( ...
            'table', types.untyped.ObjectView(table), ...
            'description', description, ...
            'data', flatData ...
        );
    end

    % Index level 1 targets the data vector; every further level targets the
    % level below it.
    target = data_vector;
    varargout = cell(1, depth);
    for iLevel = 1:depth
        varargout{iLevel} = types.hdmf_common.VectorIndex( ...
            'data', uint64(cumsum(counts{iLevel})), ...
            'target', types.untyped.ObjectView(target), ...
            'description', 'indexes data' ...
        );
        target = varargout{iLevel};
    end
end

function [flatData, counts] = flattenRows(rows, depth)
    % Concatenate the elements of all rows along the ragged (last) axis and
    % count the entries of every index level. COUNTS{k} lists, for each entry
    % of level k, how many level k-1 entries it holds (level 0 entries are the
    % elements); COUNTS{depth} has one entry per row.
    [elementDims, useShortcut] = findLayout(rows, depth);

    numRows = numel(rows);
    chunks = cell(1, numRows);
    rowCounts = zeros(numRows, 1);
    rowInnerCounts = cell(1, numRows);
    for iRow = 1:numRows
        [chunks{iRow}, rowCounts(iRow), rowInnerCounts{iRow}] = flattenItem( ...
            rows{iRow}, depth, elementDims, useShortcut, sprintf('DATA{%d}', iRow));
    end

    flatData = concatenateChunks(chunks, elementDims);
    counts = cell(1, depth);
    counts{depth} = rowCounts;
    for iLevel = 1:depth - 1
        levelCounts = cellfun(@(inner) inner{iLevel}, rowInnerCounts, 'UniformOutput', false);
        counts{iLevel} = vertcat(levelCounts{:});
    end
end

function [chunk, ownCount, innerCounts] = flattenItem(item, level, elementDims, useShortcut, label)
    % CHUNK holds the item's elements as [elementDims x nElements] (a column
    % in scalar mode). OWNCOUNT is the number of level-(LEVEL-1) entries in
    % the item, i.e. its elements when LEVEL is 1. INNERCOUNTS{k}, k < LEVEL,
    % lists the counts of the level-k entries inside the item.
    innerCounts = repmat({zeros(0, 1)}, 1, level - 1);
    if isempty(item) && (iscell(item) || isempty(elementDims))
        chunk = [];
        ownCount = 0;
        return
    end

    if iscell(item)
        if level == 1
            error("NWB:CreateIndexedColumn:InvalidRow", ...
                "%s is a cell array, but at the innermost level a row must be a " + ...
                "numeric or logical array. Increase Depth for nested rows.", label);
        end
        numEntries = numel(item);
        chunks = cell(1, numEntries);
        entryCounts = zeros(numEntries, 1);
        entryInnerCounts = cell(1, numEntries);
        for iEntry = 1:numEntries
            [chunks{iEntry}, entryCounts(iEntry), entryInnerCounts{iEntry}] = flattenItem( ...
                item{iEntry}, level - 1, elementDims, useShortcut, sprintf('%s{%d}', label, iEntry));
        end
        chunk = concatenateChunks(chunks, elementDims);
        ownCount = numEntries;
        innerCounts{level - 1} = entryCounts;
        for iLevel = 1:level - 2
            levelCounts = cellfun(@(inner) inner{iLevel}, entryInnerCounts, 'UniformOutput', false);
            innerCounts{iLevel} = vertcat(levelCounts{:});
        end
        return
    end

    if ~(isnumeric(item) || islogical(item))
        error("NWB:CreateIndexedColumn:InvalidRow", ...
            "%s must be a numeric or logical array%s. It is a %s.", ...
            label, cellHint(level), class(item));
    end

    if isempty(elementDims)
        % Scalar mode: every row is a vector, so the elements are scalars.
        chunk = item(:);
        ownCount = numel(item);
        return
    end

    [itemElementDims, levelSizes] = splitDims(item, level, numel(elementDims), useShortcut);
    if ~isequal(itemElementDims, elementDims)
        if isempty(item)
            % [] has no entries at this level. An empty array that does carry
            % the element shape, such as [k x 0 x n], declares n sub-groups
            % with no elements and is counted below.
            chunk = [];
            ownCount = 0;
            return
        end
        error("NWB:CreateIndexedColumn:InconsistentElementShape", ...
            "All elements must have the same shape. Expected elements of shape [%s], " + ...
            "but %s has size [%s]. Give a numeric row as [elementShape x ...] with the " + ...
            "ragged axes last.", ...
            join(string(elementDims), " "), label, join(string(size(item)), " "));
    end

    % Merging the trailing ragged dimensions lists the entries of the first
    % sub-group first, which is the order the index levels describe.
    chunk = reshape(item, [elementDims, prod(levelSizes)]);
    ownCount = levelSizes(level);
    for iLevel = 1:level - 1
        innerCounts{iLevel} = repmat(levelSizes(iLevel), prod(levelSizes(iLevel + 1:level)), 1);
    end
end

function [elementDims, levelSizes] = splitDims(item, level, numElementDims, useShortcut)
    % Split the size of a numeric item into its element shape and the sizes of
    % its LEVEL ragged dimensions, innermost first. MATLAB drops trailing
    % dimensions of 1 from size, so the size is first padded with ones to the
    % length the layout expects. An item with more dimensions than that keeps
    % them in ELEMENTDIMS, where the caller's shape check rejects it.
    dims = size(item);
    if useShortcut && level >= 2
        % [k x s2 x ... x sLEVEL]: one element per innermost entry.
        dims(end + 1:level) = 1;
        elementDims = dims(1:end - level + 1);
        levelSizes = [1, dims(end - level + 2:end)];
    else
        dims(end + 1:numElementDims + level) = 1;
        elementDims = dims(1:end - level);
        levelSizes = dims(end - level + 1:end);
    end
end

function [elementDims, useShortcut] = findLayout(rows, depth)
    % Decide how the numeric items of ROWS split into element shape and ragged
    % sizes. ELEMENTDIMS is [] when DEPTH is 1 and every row is a vector (the
    % elements are scalars) or when no row holds elements. As MATLAB drops
    % trailing dimensions of 1 from size, the number of element dimensions is
    % the largest any item shows; splitDims pads shorter items to it.
    % USESHORTCUT is true when the column uses the [k x nSubGroups] form,
    % which is only unambiguous while no item at level 2 or above shows the
    % full form by having more dimensions than its level.
    scan = struct('maxElementDims', -Inf, 'shortcutAllowed', true, ...
        'firstItem', [], 'firstLevel', 0);
    for iRow = 1:numel(rows)
        scan = scanItem(rows{iRow}, depth, depth == 1, scan);
    end

    elementDims = [];
    useShortcut = false;
    if isempty(scan.firstItem)
        return
    end
    useShortcut = depth >= 2 && scan.shortcutAllowed && scan.maxElementDims <= 1;
    if useShortcut
        numElementDims = 1;
    else
        numElementDims = scan.maxElementDims;
    end
    elementDims = splitDims(scan.firstItem, scan.firstLevel, numElementDims, useShortcut);
end

function scan = scanItem(item, level, vectorsAreScalars, scan)
    if iscell(item)
        % A cell at level 1 is rejected by flattenItem.
        if level >= 2
            for iEntry = 1:numel(item)
                scan = scanItem(item{iEntry}, level - 1, false, scan);
            end
        end
        return
    end
    if ~(isnumeric(item) || islogical(item)) || (vectorsAreScalars && isvector(item))
        return
    end

    numDims = ndims(item);
    scan.maxElementDims = max(scan.maxElementDims, numDims - level);
    if level >= 2 && numDims > level
        scan.shortcutAllowed = false;
    end
    % An empty array such as [k x 0 x n] still shows the layout, but only a
    % non-empty item can supply the element shape.
    if isempty(scan.firstItem) && ~isempty(item)
        scan.firstItem = item;
        scan.firstLevel = level;
    end
end

function data = concatenateChunks(chunks, elementDims)
    nonEmptyChunks = chunks(~cellfun(@isempty, chunks));
    if isempty(nonEmptyChunks)
        data = [];
        return
    end
    data = cat(numel(elementDims) + 1, nonEmptyChunks{:});
end

function hint = cellHint(level)
    if level > 1
        hint = ' or a cell array of sub-groups';
    else
        hint = '';
    end
end
