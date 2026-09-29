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
%     - text: a cell array of character vectors or a string array is a list
%       of text elements, and a character vector is one text element.
%       DATA_VECTOR.data is then a column cell array of character vectors.
%     - compound: a table holds one compound element per table row, a struct
%       array one element per struct, and a scalar struct whose fields are
%       equal-length columns one element per column entry. DATA_VECTOR.data
%       is then a table, which is written as a compound dataset (for example
%       PlaneSegmentation.pixel_mask).
%   A column holds elements of one kind: numeric, text or compound.
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
%     - [] or {} for a row with no sub-groups, or [elementDims x 0 x nSubGroups]
%       for nSubGroups sub-groups that hold no elements.
%   MATLAB drops trailing dimensions of 1, so a [k x m] row fits both numeric
%   forms, and DATA is read one way as a whole. If any numeric row has more
%   than n dimensions, every numeric row is read in the full form with its
%   omitted trailing dimensions of 1 restored: a [k x m] row is one sub-group
%   of m elements (for Units.waveforms, one spike event on m electrodes), and
%   a row with one element per sub-group must be given as [k x 1 x nSubGroups]
%   (one electrode), since MATLAB keeps a dimension of 1 that is not the last.
%   Otherwise every [k x m] row is the shortcut form. The cell form is read
%   the same way in either case. Text works in the cell form: each sub-group
%   is a text row as described above.
%   EXAMPLE (waveforms of 2 units with 3 and 4 spikes on one electrode):
%     unit1 = rand(40, 3); unit2 = rand(40, 4);   % [num_samples x num_spikes]
%     [wf, wfIndex, wfIndexIndex] = util.create_indexed_column({unit1, unit2}, 'spike waveforms', 'Depth', 2);
%     units.waveforms = wf;
%     units.waveforms_index = wfIndex;
%     units.waveforms_index_index = wfIndexIndex;
%
%   [DATA_VECTOR, DATA_INDEX] = CREATE_INDEXED_COLUMN(FLATDATA, __, 'ElementsPerRow', COUNTS)
%   builds the same column from data that is already flat, without one array
%   per row. FLATDATA holds the elements of all rows in row order, and
%   COUNTS(i) is the number of elements in row i. FLATDATA is a numeric
%   vector (scalar elements), a numeric array [elementDims x nElements], text
%   (a cell array of character vectors or a string array), or compound data
%   (a table, a struct array or a scalar struct of columns). SUM(COUNTS) must
%   equal the number of elements. This form builds a column of depth 1.
%   EXAMPLE (pixel masks of 2 ROIs with 3 and 2 pixels):
%     pixels = table(uint32([1;2;3;7;8]), uint32([4;4;4;9;9]), single(ones(5,1)), ...
%         'VariableNames', {'x', 'y', 'weight'});
%     [mask, maskIndex] = util.create_indexed_column(pixels, 'pixel masks', 'ElementsPerRow', [3 2]);
%
%   See also types.hdmf_common.DynamicTable/addRaggedArray

    arguments
        data
        description = ''
        table = []
        options.Depth (1,1) {mustBeInteger, mustBePositive} = 1
        options.ElementsPerRow {mustBeNumeric, mustBeInteger, mustBeNonnegative} = []
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

    if isempty(options.ElementsPerRow)
        if ~iscell(data)
            error("NWB:CreateIndexedColumn:InvalidData", ...
                "DATA must be a cell array with one cell per row. To give data that " + ...
                "is already flat, also give ElementsPerRow.");
        end
        [flatData, counts] = flattenRows(data, depth);
    else
        if depth ~= 1
            error("NWB:CreateIndexedColumn:ElementsPerRowNeedsDepth1", ...
                "ElementsPerRow builds a column of depth 1. Give the rows as a cell " + ...
                "array to build a column of depth %d.", depth);
        end
        [flatData, numElements] = normalizeFlatData(data);
        elementsPerRow = double(options.ElementsPerRow(:));
        if sum(elementsPerRow) ~= numElements
            error("NWB:CreateIndexedColumn:ElementCountMismatch", ...
                "ElementsPerRow adds up to %d elements, but DATA holds %d.", ...
                sum(elementsPerRow), numElements);
        end
        counts = {elementsPerRow};
    end

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
    layout = findLayout(rows, depth);

    numRows = numel(rows);
    chunks = cell(1, numRows);
    rowCounts = zeros(numRows, 1);
    rowInnerCounts = cell(1, numRows);
    for iRow = 1:numRows
        [chunks{iRow}, rowCounts(iRow), rowInnerCounts{iRow}] = flattenItem( ...
            rows{iRow}, depth, layout, sprintf('DATA{%d}', iRow));
    end

    flatData = concatenateChunks(chunks, layout);
    if layout.kind == "compound" && ~isempty(flatData)
        flatData = struct2table(flatData);
    end
    counts = cell(1, depth);
    counts{depth} = rowCounts;
    for iLevel = 1:depth - 1
        levelCounts = cellfun(@(inner) inner{iLevel}, rowInnerCounts, 'UniformOutput', false);
        counts{iLevel} = vertcat(levelCounts{:});
    end
end

function [chunk, ownCount, innerCounts] = flattenItem(item, level, layout, label)
    % CHUNK holds the item's elements as [elementDims x nElements] (a column
    % in scalar mode, a column cell array of character vectors for text, a
    % scalar struct of columns for compound elements). OWNCOUNT is the number
    % of level-(LEVEL-1) entries in the item, i.e. its elements when LEVEL is
    % 1. INNERCOUNTS{k}, k < LEVEL, lists the counts of the level-k entries
    % inside the item.
    elementDims = layout.elementDims;
    innerCounts = repmat({zeros(0, 1)}, 1, level - 1);
    if isempty(item) && (iscell(item) || isempty(elementDims))
        chunk = [];
        ownCount = 0;
        return
    end

    if layout.kind == "compound" && level == 1
        if ~isCompoundRow(item)
            error("NWB:CreateIndexedColumn:InconsistentElementType", ...
                "%s must be compound data (a table, a struct array or a scalar struct " + ...
                "of columns) like the other rows of the column. It is a %s.", ...
                label, class(item));
        end
        [chunk, ownCount] = compoundColumns(item, label);
        return
    end

    if layout.kind == "text" && level == 1
        if ~isTextRow(item)
            error("NWB:CreateIndexedColumn:InconsistentElementType", ...
                "%s must be text (a cell array of character vectors, a string array or " + ...
                "a character vector) like the other rows of the column. It is a %s.", ...
                label, class(item));
        end
        if ischar(item)
            chunk = {item};
        else
            chunk = cellstr(item(:));
        end
        ownCount = numel(chunk);
        return
    end

    if iscell(item)
        if level == 1
            error("NWB:CreateIndexedColumn:InvalidRow", ...
                "%s is a cell array, but at the innermost level a row must be a " + ...
                "numeric or logical array or text. Increase Depth for nested rows.", label);
        end
        numEntries = numel(item);
        chunks = cell(1, numEntries);
        entryCounts = zeros(numEntries, 1);
        entryInnerCounts = cell(1, numEntries);
        for iEntry = 1:numEntries
            [chunks{iEntry}, entryCounts(iEntry), entryInnerCounts{iEntry}] = flattenItem( ...
                item{iEntry}, level - 1, layout, sprintf('%s{%d}', label, iEntry));
        end
        chunk = concatenateChunks(chunks, layout);
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

    [itemElementDims, levelSizes] = splitDims(item, level, numel(elementDims), layout.useShortcut);
    if ~isequal(itemElementDims, elementDims)
        if isempty(item) && ismatrix(item)
            % An empty matrix such as [] or zeros(1, 0) has no entries at this
            % level. An empty array with more dimensions declares entries,
            % such as [k x 0 x n] for n sub-groups with no elements, so its
            % element shape must match like any other row's.
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

function layout = findLayout(rows, depth)
    % Decide how the items of ROWS are read. LAYOUT.KIND is "numeric", "text"
    % or "compound". For numeric elements, LAYOUT.ELEMENTDIMS is the element
    % shape, or [] when DEPTH is 1 and every row is a vector (the elements are
    % scalars) or when no row holds elements. As MATLAB drops trailing dimensions of 1
    % from size, the number of element dimensions is the largest any item
    % shows; splitDims pads shorter items to it. LAYOUT.USESHORTCUT is true
    % when the column uses the [k x nSubGroups] form, which is only
    % unambiguous while no item at level 2 or above shows the full form by
    % having more dimensions than its level.
    scan = struct('maxElementDims', -Inf, 'shortcutAllowed', true, ...
        'firstItem', [], 'firstLevel', 0, ...
        'hasNumeric', false, 'hasText', false, 'hasCompound', false);
    for iRow = 1:numel(rows)
        scan = scanItem(rows{iRow}, depth, depth == 1, scan);
    end

    kinds = ["numeric", "text", "compound"];
    presentKinds = kinds([scan.hasNumeric, scan.hasText, scan.hasCompound]);
    if numel(presentKinds) > 1
        error("NWB:CreateIndexedColumn:InconsistentElementType", ...
            "A column holds elements of one kind, but DATA has %s elements.", ...
            strjoin(presentKinds, " and "));
    end
    layout = struct('elementDims', [], 'useShortcut', false, 'kind', "numeric");
    if ~isempty(presentKinds)
        layout.kind = presentKinds;
    end
    if layout.kind ~= "numeric" || isempty(scan.firstItem)
        return
    end
    layout.useShortcut = depth >= 2 && scan.shortcutAllowed && scan.maxElementDims <= 1;
    if layout.useShortcut
        numElementDims = 1;
    else
        numElementDims = scan.maxElementDims;
    end
    layout.elementDims = splitDims( ...
        scan.firstItem, scan.firstLevel, numElementDims, layout.useShortcut);
end

function scan = scanItem(item, level, vectorsAreScalars, scan)
    if level == 1 && isTextRow(item)
        scan.hasText = scan.hasText || ~isempty(item);
        return
    end
    if level == 1 && isCompoundRow(item)
        scan.hasCompound = scan.hasCompound || ~isempty(item);
        return
    end
    if iscell(item)
        % A cell at level 1 is rejected by flattenItem.
        if level >= 2
            for iEntry = 1:numel(item)
                scan = scanItem(item{iEntry}, level - 1, false, scan);
            end
        end
        return
    end
    if ~(isnumeric(item) || islogical(item))
        return
    end
    scan.hasNumeric = scan.hasNumeric || ~isempty(item);
    if vectorsAreScalars && isvector(item)
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

function data = concatenateChunks(chunks, layout)
    nonEmptyChunks = chunks(~cellfun(@isempty, chunks));
    if isempty(nonEmptyChunks)
        data = [];
        return
    end
    if layout.kind == "compound"
        data = joinCompoundColumns(nonEmptyChunks);
    else
        data = cat(numel(layout.elementDims) + 1, nonEmptyChunks{:});
    end
end

function [flatData, numElements] = normalizeFlatData(data)
    % Put flat DATA in the form the column stores and count its elements.
    if isnumeric(data) || islogical(data)
        if isvector(data) || isempty(data)
            flatData = data(:);
            numElements = numel(data);
        else
            flatData = data;
            numElements = size(data, ndims(data));
        end
    elseif iscellstr(data) || isstring(data)
        flatData = cellstr(data(:));
        numElements = numel(flatData);
    elseif isCompoundRow(data)
        [columns, numElements] = compoundColumns(data, 'DATA');
        flatData = struct2table(columns);
    else
        error("NWB:CreateIndexedColumn:InvalidData", ...
            "Flat DATA must be numeric, logical, text or compound data. It is a %s.", ...
            class(data));
    end
end

function [columns, numElements] = compoundColumns(item, label)
    % Compound elements as a scalar struct with one column per field, whether
    % they were given as a table, a struct array or a scalar struct of columns.
    if istable(item)
        columns = table2struct(item, 'ToScalar', true);
    elseif isscalar(item)
        columns = structfun(@toColumn, item, 'UniformOutput', false);
    else
        columns = struct();
        names = fieldnames(item);
        for iName = 1:numel(names)
            values = {item.(names{iName})};
            if ~all(cellfun(@(value) isscalar(value) || ischar(value), values))
                error("NWB:CreateIndexedColumn:InconsistentElementShape", ...
                    "In %s, every element of a struct array must have scalar fields. " + ...
                    "Give columns of values as a scalar struct instead.", label);
            end
            if all(cellfun(@ischar, values))
                columns.(names{iName}) = values(:);
            else
                columns.(names{iName}) = vertcat(values{:});
            end
        end
    end
    lengths = structfun(@numel, columns);
    if isempty(lengths) || any(lengths ~= lengths(1))
        error("NWB:CreateIndexedColumn:InconsistentElementShape", ...
            "%s must have fields of equal length, one entry per compound element.", label);
    end
    numElements = lengths(1);
end

function column = toColumn(value)
    if ischar(value)
        column = {value};
    else
        column = value(:);
    end
end

function joined = joinCompoundColumns(chunks)
    % Join scalar structs of columns field by field. Building one table at the
    % end avoids creating a table for every row.
    names = fieldnames(chunks{1});
    for iChunk = 2:numel(chunks)
        if ~isequal(sort(fieldnames(chunks{iChunk})), sort(names))
            error("NWB:CreateIndexedColumn:InconsistentElementShape", ...
                "All compound elements must have the same fields: %s.", strjoin(names, ", "));
        end
    end
    joined = struct();
    for iName = 1:numel(names)
        parts = cellfun(@(chunk) chunk.(names{iName}), chunks, 'UniformOutput', false);
        joined.(names{iName}) = vertcat(parts{:});
    end
end

function tf = isCompoundRow(item)
    tf = istable(item) || isstruct(item);
end

function hint = cellHint(level)
    if level > 1
        hint = ' or a cell array of sub-groups';
    else
        hint = '';
    end
end

function tf = isTextRow(item)
    tf = iscellstr(item) || isstring(item) || ischar(item);
end
