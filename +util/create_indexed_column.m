function [data_vector, varargout] = create_indexed_column(data, description, table, options)
% util.create_indexed_column - Create the VectorData and VectorIndex objects of a ragged DynamicTable column.
%
% Syntax:
%  [data_vector, data_index] = util.create_indexed_column(data) Creates a
%  VectorData that holds the elements of all rows, and a VectorIndex that
%  holds the position of the last element of each row.
%
%  [data_vector, data_index] = util.create_indexed_column(data, description)
%  Also sets the description of the VectorData.
%
%  [table_region, data_index] = util.create_indexed_column(data, description, table)
%  Creates a DynamicTableRegion that references table instead of a
%  VectorData. The elements are 0-based row indices into table, and the
%  DynamicTableRegion is indexed the same way as a VectorData.
%
%  [data_vector, index1, ..., indexN] = util.create_indexed_column(data, 'Depth', n)
%  Creates a column with n VectorIndex objects. With Depth 2 each row
%  holds sub-groups, and each sub-group holds elements. An example is the
%  'waveforms' column of Units: a row is a unit, a sub-group is a spike
%  event, and an element is the waveform on one electrode.
%
%  [data_vector, index1, index2] = util.create_indexed_column(data, 'Depth', 2, 'ElementsPerSubGroup', numElements)
%  States the number of elements in each sub-group of the numeric rows,
%  so that it is not read from the dimensions of the rows.
%
% Input Arguments:
%  - data (cell) -
%    A cell array with one cell per row.
%
%    With Depth 1, each cell holds the elements of that row in one of
%    these forms:
%
%    - A numeric or logical vector, as a row or a column -
%      One scalar element per value. When every row is a vector, the data
%      of data_vector is a column vector that holds all elements.
%
%    - A numeric or logical array [elementDims x nElements] -
%      nElements elements of size elementDims, along the last dimension.
%      This is the orientation of the data property of any MatNWB
%      VectorData. Rows are concatenated along that dimension, so the data
%      of data_vector is [elementDims x totalElements]. On disk that
%      dimension comes first, as the schema requires.
%
%    - A string array, character vector, struct array or array of objects
%      (such as types.untyped.ObjectView references), as a vector -
%      One element per string, character, struct or object. The data of
%      data_vector keeps the class, as a column.
%
%    - [] or an empty array of any size -
%      A row with no elements.
%
%    All rows must hold elements of the same class (for example all
%    int32, not int32 and double), and struct rows the same fields. All
%    array rows must share elementDims.
%
%    Trailing dimensions of size 1 may be omitted, as MATLAB omits them
%    from the size of an array. The number of element dimensions is the
%    largest that any row shows, and rows with fewer dimensions are padded
%    with ones. A row that holds a single element is thus a [k x 1] column
%    vector when elements are k-sample vectors, or a [k x m] matrix when
%    elements are [k x m].
%
%    With Depth n, each cell holds the sub-groups of that row in one of
%    these forms:
%
%    - A cell array with one cell per sub-group -
%      Each cell is in a form that is valid for depth n-1. With Depth 2
%      that is an [elementDims x nElements] array. A vector is read as an
%      array here, not as a list of scalars: a [k x 1] column vector is one
%      k-sample element, and a [1 x m] row vector is m single-sample
%      elements.
%
%    - A numeric array [elementDims x nElements x nSubGroups], with
%      Depth 2 -
%      Every sub-group holds nElements elements. For the 'waveforms'
%      column of Units this is one
%      [num_samples x num_electrodes x num_spike_events] array per unit.
%      It is the (num_spikes, num_electrodes, num_samples) array that
%      Units.add_unit of PyNWB takes, with its dimensions reversed as for
%      any other MatNWB dataset. A unit with a single spike event is then
%      [num_samples x num_electrodes], with its trailing dimension of
%      size 1 omitted.
%
%    - A numeric matrix [k x nSubGroups], with Depth 2 (the shortcut
%      form) -
%      Every sub-group holds a single k-sample element, as for spike
%      waveforms on one electrode.
%
%    - [], {} or an empty matrix of any size -
%      A row with no sub-groups. An [elementDims x 0 x nSubGroups] array
%      is nSubGroups sub-groups that hold no elements. MATLAB drops a
%      trailing dimension of size 1, so a single sub-group with no
%      elements is given in the cell form, as {[]}.
%
%    A [k x m] row fits both numeric forms, because MATLAB drops trailing
%    dimensions of size 1. The column is therefore read one way as a
%    whole. If any numeric row has more than n dimensions, every numeric
%    row is read as [elementDims x nElements x nSubGroups], with its
%    omitted trailing dimensions of size 1 restored. A [k x m] row is then
%    one sub-group of m elements (for 'waveforms', one spike event on m
%    electrodes), and a row with one element per sub-group must be given
%    as [k x 1 x nSubGroups] (one electrode), because MATLAB keeps a
%    dimension of size 1 that is not the last. Otherwise every [k x m] row
%    is read in the shortcut form. The cell form is read the same way in
%    either case.
%
%    A column whose elements have more than one value needs at least two
%    elements in total. The data of a single element, [elementDims x 1],
%    is written without its last dimension and read back as a list of
%    smaller elements. Such input raises
%    NWB:CreateIndexedColumn:SingleElementColumn. To store such a column,
%    build the VectorData directly with a DataPipe that states every
%    dimension.
%
%  - description (text) -
%    Description of the VectorData. Default: 'no description'.
%
%    A description that starts the name of a name-value argument, in any
%    letter case, such as 'depth', is read as that name when an even
%    number of arguments follows data. Set the description property of
%    data_vector after the call instead.
%
%  - table (DynamicTable | text) -
%    The table that the column references: the DynamicTable object, or
%    the path of the table in the file as text. The function wraps it in
%    an ObjectView.
%
%  - options (name-value pairs) -
%    Optional name-value pairs. Available options:
%
%    - Depth (integer) -
%      Number of VectorIndex objects. Default: 1.
%
%    - ElementsPerSubGroup (positive integer | vector of positive integers) -
%      Number of elements in each sub-group of the numeric rows of a
%      column of depth 2, as one value or one value per row. A numeric row
%      is then [elementDims x nElements], with the elements of the first
%      sub-group first and nElements a multiple of the value for that
%      row, or [elementDims x value x nSubGroups]. A [k x m] row is
%      m/value sub-groups whatever the other rows are, and no dimension of
%      size 1 is needed. For the 'waveforms' column of Units, the value is
%      the number of electrodes of each unit.
%
%      Elements are vectors unless a row shows more element dimensions,
%      by being given in the second form or as a cell array. A row given
%      as a cell array states its sub-groups itself and is not compared
%      with the value.
%
% Output Arguments:
%  - data_vector (VectorData | DynamicTableRegion) -
%    The elements of all rows.
%
%  - index1, ..., indexN (VectorIndex) -
%    One VectorIndex per level. index1 targets data_vector and has one
%    value per innermost sub-group, or per row when Depth is 1. Every
%    further index targets the one before it, and indexN has one value
%    per row. Assign them to the column and its '<column>_index',
%    '<column>_index_index', ... properties.
%
% Usage:
%  Example 1 - Rows of 3 and 4 scalar elements::
%
%    [data_vector, data_index] = util.create_indexed_column({[1 2 3], [1 2 3 4]});
%    % data_vector.data is [1;2;3;1;2;3;4] and data_index.data is [3;7].
%
%  Example 2 - Rows of 2 and 3 elements that each have 4 samples::
%
%    [data_vector, data_index] = util.create_indexed_column({rand(4, 2), rand(4, 3)});
%    % data_vector.data is [4 x 5] and data_index.data is [2;5].
%
%  Example 3 - Waveforms of 2 units with 2 and 3 spike events on 3 electrodes::
%
%    % Each spike event is a [num_samples x num_electrodes] matrix.
%    unit1 = {rand(40, 3), rand(40, 3)};
%    unit2 = {rand(40, 3), rand(40, 3), rand(40, 3)};
%    [wf, wfIndex, wfIndexIndex] = util.create_indexed_column({unit1, unit2}, 'spike waveforms', 'Depth', 2);
%    units.waveforms = wf;
%    units.waveforms_index = wfIndex;
%    units.waveforms_index_index = wfIndexIndex;
%
%  Example 4 - Waveforms of 2 units with 3 and 4 spikes on one electrode::
%
%    unit1 = rand(40, 3);   % [num_samples x num_spikes]
%    unit2 = rand(40, 4);
%    [wf, wfIndex, wfIndexIndex] = util.create_indexed_column({unit1, unit2}, 'spike waveforms', 'Depth', 2);
%
%  Example 5 - Units with 3 electrodes and 1 electrode, each given as one matrix of all waveforms::
%
%    unit1 = rand(40, 6);   % [num_samples x (3 electrodes * 2 spike events)]
%    unit2 = rand(40, 4);   % [num_samples x (1 electrode * 4 spike events)]
%    [wf, wfIndex, wfIndexIndex] = util.create_indexed_column({unit1, unit2}, ...
%        'spike waveforms', 'Depth', 2, 'ElementsPerSubGroup', [3 1]);
%    % wfIndex.data is [3;6;7;8;9;10] and wfIndexIndex.data is [2;6].
%
% See also:
%   types.hdmf_common.DynamicTable/addRaggedArray

% Terms:
%  - row -
%    The data of one table row, given as one cell of data.
%
%  - element -
%    One value of the column. A numeric element is a scalar, or an array
%    of a size that all elements of the column share. That size is
%    written elementDims. The elements of all rows are stored along
%    the last dimension of one array.
%
%  - sub-group -
%    A group of elements within a row. In the 'waveforms' column of
%    Units, a row is a unit, a sub-group is a spike event, and an element
%    is the waveform on one electrode.
%
%  - depth -
%    The number of VectorIndex objects of the column. With depth 1 a row
%    holds elements. With depth 2 a row holds sub-groups, and each
%    sub-group holds elements.

    arguments
        data
        description = ''
        table = []
        options.Depth (1,1) {mustBeInteger, mustBePositive} = 1
        options.ElementsPerSubGroup {mustBeNumeric, mustBeInteger, mustBePositive}
    end

    depth = options.Depth;
    if nargout > depth+1
        error("NWB:CreateIndexedColumn:TooManyOutputs", ...
            "A column of depth %d has %d outputs: the data vector and %d index level(s).", ...
            depth, depth+1, depth);
    end
    hasElementsPerSubGroup = isfield(options, 'ElementsPerSubGroup');
    if hasElementsPerSubGroup && depth ~= 2
        error("NWB:CreateIndexedColumn:ElementsPerSubGroupNeedsDepth2", ...
            "ElementsPerSubGroup applies to a column of depth 2, but Depth is %d.", depth);
    end
    if isempty(description)
        description = 'no description';
    else
        description = char(description);
    end

    elementsPerSubGroup = [];
    if hasElementsPerSubGroup
        elementsPerSubGroup = expandToRows(options.ElementsPerSubGroup, numel(data));
    end
    [flatData, groupLengths] = flattenRows(data, depth, elementsPerSubGroup);

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
            'data', uint64(cumsum(groupLengths{iLevel})), ...
            'target', types.untyped.ObjectView(target), ...
            'description', 'indexes data' ...
        );
        target = varargout{iLevel};
    end
end

% Local functions
%
% Terms used below, in addition to the terms listed after the help text:
%  - group - A row or a sub-group.
%  - level - The level of a group. A group of level 1 holds elements. A
%    group of level n holds groups of level n-1, which are its sub-groups.
%    A row has the level depth, and VectorIndex n has one value per group
%    of level n.
%  - length - The number of elements (level 1) or sub-groups (higher
%    levels) that a group holds directly.
%  - position - Where a group is in data, as a vector of cell indices:
%    [3 2] is the second sub-group of row 3.
%  - ragged dimensions - The trailing dimensions of a numeric array that
%    count its elements and sub-groups, written raggedDims. The size of
%    the array is [elementDims x raggedDims].
%  - shortcut form - A numeric row [k x nSubGroups] of a column of depth
%    2, in which every sub-group holds one element of k values.

function elementsPerSubGroup = expandToRows(elementsPerSubGroup, numRows)
% expandToRows - Return ElementsPerSubGroup as a column with one value per row.
%
% The option is given as one value for all rows, or as one value per row.
% Any other number of values raises
% NWB:CreateIndexedColumn:ElementsPerSubGroupCountMismatch.

    if isscalar(elementsPerSubGroup)
        elementsPerSubGroup = repmat(double(elementsPerSubGroup), numRows, 1);
    elseif numel(elementsPerSubGroup) == numRows
        elementsPerSubGroup = double(elementsPerSubGroup(:));
    else
        error("NWB:CreateIndexedColumn:ElementsPerSubGroupCountMismatch", ...
            "ElementsPerSubGroup must be a scalar or hold one value per row. The data " + ...
            "has %d row(s), but ElementsPerSubGroup has %d value(s).", ...
            numRows, numel(elementsPerSubGroup));
    end
end

function [flatData, groupLengths] = flattenRows(rows, depth, elementsPerSubGroup)
% flattenRows - Concatenate the elements of all rows, and return the length of every row and sub-group.
%
% The layout is inferred from all rows before any row is flattened,
% because the size of one element cannot be read from a single row (see
% inferLayout).
%
% Raises NWB:CreateIndexedColumn:SingleElementColumn when the column
% holds a single element that has more than one value, because such data
% is not read back as one element.
%
% Input arguments:
%  - rows - The cell array with one cell per row.
%  - depth - The number of levels of the column.
%  - elementsPerSubGroup - The number of elements in each sub-group of the
%    numeric rows, as one value per row. It is [] when that number is read
%    from the dimensions of the rows.
%
% Output arguments:
%  - flatData - The elements of all rows, concatenated along the last
%    dimension in row order. It becomes the data of the VectorData.
%  - groupLengths - A cell array with one vector per level, innermost
%    first. groupLengths{n} holds the length of every group of level n in
%    row order, so groupLengths{depth} holds one value per row. The
%    cumulative sum of groupLengths{n} is the data of VectorIndex n.

    hasElementsPerSubGroup = ~isempty(elementsPerSubGroup);
    layout = inferLayout(rows, depth, hasElementsPerSubGroup);

    numRows = numel(rows);
    rowElements = cell(1, numRows);
    rowLengths = zeros(numRows, 1);
    rowInnerLengths = cell(1, numRows);
    for iRow = 1:numRows
        if hasElementsPerSubGroup
            layout.elementsPerSubGroup = elementsPerSubGroup(iRow);
        end
        [rowElements{iRow}, rowLengths(iRow), rowInnerLengths{iRow}] = flattenGroup( ...
            rows{iRow}, depth, layout, iRow);
    end

    flatData = concatenateElements(rowElements, layout);
    groupLengths = cell(1, depth);
    groupLengths{depth} = rowLengths;
    for iLevel = 1:depth-1
        lengthsAtLevel = cellfun(@(inner) inner{iLevel}, rowInnerLengths, 'UniformOutput', false);
        groupLengths{iLevel} = vertcat(lengthsAtLevel{:});
    end

    % The data of a column with one element is [elementDims x 1]. An array in
    % memory is written without that last dimension: one 40-sample element
    % is a [40 x 1] array, which becomes a dataset of 40 scalar elements, and
    % the row reads back as one sample. A DataPipe states every dimension of
    % the dataset, so it can hold such a column.
    numElements = sum(groupLengths{1});
    if numElements == 1 && prod(layout.elementDims) > 1
        elementShape = join(string(layout.elementDims), " ");
        error("NWB:CreateIndexedColumn:SingleElementColumn", ...
            "The column holds a single element of shape [%s]. Its data " + ...
            "is written without the dimension for the number of elements and read " + ...
            "back as %d smaller elements. To store such a column, build the " + ...
            "VectorData and VectorIndex objects directly, with the data in a " + ...
            "types.untyped.DataPipe that states every dimension " + ...
            "('maxSize', [%s Inf], 'axis', %d).", ...
            elementShape, layout.elementDims(end), elementShape, numel(layout.elementDims)+1);
    end
end

function [elements, groupLength, innerLengths] = flattenGroup(group, level, layout, position)
% flattenGroup - Return the elements of one row or sub-group as one array, with the lengths of the groups in it.
%
% A group of level 1 holds its elements in one array, which is checked
% against the layout and returned. A group of a higher level is a cell
% array of sub-groups: the function calls itself for each sub-group and
% joins the results.
%
% A group of a higher level can also be one numeric array. Its trailing
% dimensions then state the sub-groups (see splitDims), and the array is
% reshaped without calling the function again.
%
% Input arguments:
%  - group - The row or sub-group, as it was given in data.
%  - level - The level of the group.
%  - layout - How the groups are read. See inferLayout for its fields.
%  - position - The position of the group, used in error messages.
%
% Output arguments:
%  - elements - The elements of the group as one array. It is
%    [elementDims x nElements] for array elements, and a column for
%    scalars, strings, characters, structs and objects.
%  - groupLength - The length of the group.
%  - innerLengths - A cell array with one vector per level below the
%    level of the group. innerLengths{n} holds the length of every group
%    of level n inside the group.

    elementDims = layout.elementDims;
    innerLengths = repmat({zeros(0, 1)}, 1, level-1);
    % An innermost group without elements is a row or sub-group with no
    % elements, whatever its size.
    if isempty(group) && (iscell(group) || isempty(elementDims) || level == 1)
        elements = [];
        groupLength = 0;
        return
    end

    if level == 1 && isTextOrStructOrObject(group)
        if ~isvector(group)
            error("NWB:CreateIndexedColumn:InvalidRow", ...
                "%s must be a vector of strings, characters, structs or objects. " + ...
                "It is a %s of size [%s].", ...
                formatPosition(position), class(group), join(string(size(group)), " "));
        end
        elements = group(:);
        if isstruct(group)
            % Concatenating structs needs the fields in the same order.
            elements = orderfields(elements, layout.structFields);
        end
        groupLength = numel(group);
        return
    end

    if iscell(group)
        if level == 1
            error("NWB:CreateIndexedColumn:InvalidRow", ...
                "%s is a cell array, but at the innermost level a row must be a " + ...
                "numeric or logical array, or a vector of strings, characters, " + ...
                "structs or objects. Increase Depth for nested rows.", formatPosition(position));
        end
        numSubGroups = numel(group);
        subGroupElements = cell(1, numSubGroups);
        subGroupLengths = zeros(numSubGroups, 1);
        subGroupInnerLengths = cell(1, numSubGroups);
        for iSubGroup = 1:numSubGroups
            [subGroupElements{iSubGroup}, subGroupLengths(iSubGroup), ...
                subGroupInnerLengths{iSubGroup}] = flattenGroup( ...
                group{iSubGroup}, level-1, layout, [position, iSubGroup]);
        end
        elements = concatenateElements(subGroupElements, layout);
        groupLength = numSubGroups;
        innerLengths{level-1} = subGroupLengths;
        for iLevel = 1:level-2
            lengthsAtLevel = cellfun(@(inner) inner{iLevel}, subGroupInnerLengths, 'UniformOutput', false);
            innerLengths{iLevel} = vertcat(lengthsAtLevel{:});
        end
        return
    end

    if ~(isnumeric(group) || islogical(group))
        error("NWB:CreateIndexedColumn:InvalidRow", ...
            "%s must be a numeric or logical array, or a vector of strings, " + ...
            "characters, structs or objects%s. It is a %s.", ...
            formatPosition(position), cellFormHint(level), class(group));
    end

    if isempty(elementDims)
        % Scalar mode: every row is a vector, so the elements are scalars.
        elements = group(:);
        groupLength = numel(group);
        return
    end

    if isempty(group) && ismatrix(group)
        % An empty matrix such as [], zeros(1, 0) or zeros(k, 0) has no
        % sub-groups, whatever its size. An empty array with more dimensions
        % declares sub-groups, such as [k x 0 x n] for n sub-groups with no
        % elements, so its element shape must match like any other row's.
        elements = [];
        groupLength = 0;
        return
    end

    [groupElementDims, raggedDims] = splitDims(group, level, numel(elementDims), layout.useShortcut);
    if ~isequal(groupElementDims, elementDims)
        error("NWB:CreateIndexedColumn:InconsistentElementShape", ...
            "All elements must have the same shape. Expected elements of shape [%s], " + ...
            "but %s has size [%s]. Give a numeric row as [elementShape x ...] with the " + ...
            "ragged axes last.", ...
            join(string(elementDims), " "), formatPosition(position), join(string(size(group)), " "));
    end
    if level == 2 && ~isempty(layout.elementsPerSubGroup)
        raggedDims = regroupElements(raggedDims, layout.elementsPerSubGroup, group, position);
    end

    % Merging the trailing ragged dimensions lists the elements of the first
    % sub-group first, which is the order the index levels describe.
    elements = reshape(group, [elementDims, prod(raggedDims)]);
    groupLength = raggedDims(level);
    for iLevel = 1:level-1
        innerLengths{iLevel} = repmat(raggedDims(iLevel), prod(raggedDims(iLevel+1:level)), 1);
    end
end

function [elementDims, raggedDims] = splitDims(array, level, numElementDims, useShortcut)
% splitDims - Split the size of a numeric array into the size of one element and its ragged dimensions.
%
% The array of a group of level n has the size [elementDims x raggedDims].
% raggedDims holds n values, innermost first: the number of elements in
% each sub-group, then the number of sub-groups, and so on. For a group of
% level 1 it is the number of elements.
%
% MATLAB drops trailing dimensions of size 1 from the size of an array,
% so the size is first padded with ones to numElementDims + level
% dimensions. An array with more dimensions than that keeps them in
% elementDims, where the size check of the caller rejects it.
%
% With useShortcut, the array of a group of level 2 or higher is read in
% the shortcut form [k x s2 x ... x s_level]. Each innermost sub-group
% then holds one element of k values, so raggedDims starts with 1.
%
% Input arguments:
%  - array - The numeric array.
%  - level - The level of the group that the array was given for.
%  - numElementDims - The number of dimensions of one element.
%  - useShortcut - True when the column is read in the shortcut form.

    dims = size(array);
    if useShortcut && level >= 2
        % [k x s2 x ... x s_level]: one element per innermost sub-group.
        dims(end+1:level) = 1;
        elementDims = dims(1:end-level+1);
        raggedDims = [1, dims(end-level+2:end)];
    else
        dims(end+1:numElementDims+level) = 1;
        elementDims = dims(1:end-level);
        raggedDims = dims(end-level+1:end);
    end
end

function raggedDims = regroupElements(raggedDims, elementsPerSubGroup, array, position)
% regroupElements - Divide the elements of a numeric row into sub-groups of the stated size.
%
% The function is used when ElementsPerSubGroup is given, for a row of a
% column of depth 2. raggedDims is [nElements, nSubGroups], as the size of
% the array states them:
%  - A row given as [elementDims x nElements] states all its elements as
%    one sub-group. They are divided into sub-groups of
%    elementsPerSubGroup elements, so nElements must be a multiple of
%    that number.
%  - A row given as [elementDims x nElements x nSubGroups] must state
%    elementsPerSubGroup elements in each sub-group.
% Any other size raises NWB:CreateIndexedColumn:ElementsPerSubGroupMismatch.
%
% Input arguments:
%  - raggedDims - [nElements, nSubGroups], from splitDims.
%  - elementsPerSubGroup - The stated number of elements in each
%    sub-group of this row.
%  - array - The numeric array of the row, used in the error message.
%  - position - The position of the row, used in the error message.

    numElements = raggedDims(1);
    numSubGroups = raggedDims(2);
    if numElements == elementsPerSubGroup
        return
    end
    if numSubGroups == 1 && mod(numElements, elementsPerSubGroup) == 0
        raggedDims = [elementsPerSubGroup, numElements/elementsPerSubGroup];
        return
    end
    error("NWB:CreateIndexedColumn:ElementsPerSubGroupMismatch", ...
        "%s has size [%s], which does not divide into sub-groups of %d element(s). " + ...
        "With ElementsPerSubGroup, give a numeric row as [elementShape x nElements] " + ...
        "with nElements a multiple of %d, or as [elementShape x %d x nSubGroups].", ...
        formatPosition(position), join(string(size(array)), " "), elementsPerSubGroup, ...
        elementsPerSubGroup, elementsPerSubGroup);
end

function layout = inferLayout(rows, depth, hasElementsPerSubGroup)
% inferLayout - Decide how the rows are read, from the classes and sizes of all rows.
%
% The size of one element cannot be read from a single row. MATLAB drops
% trailing dimensions of size 1, so a row can show fewer element
% dimensions than the elements have. All rows are therefore inspected
% first (see inspectGroup), and the layout is derived from the findings.
%
% Input arguments:
%  - rows - The cell array with one cell per row.
%  - depth - The number of levels of the column.
%  - hasElementsPerSubGroup - True when ElementsPerSubGroup is given.
%
% The layout is a struct with the fields:
%  - elementDims - The size of one element of a column of numeric arrays,
%    such as [40 3]. It is [] when the elements are scalars, strings,
%    characters, structs or objects, and when no row holds an element or
%    declares sub-groups.
%  - useShortcut - True when the numeric rows of a column of depth 2 or
%    more are read in the shortcut form. A [k x m] row fits both the
%    shortcut form and the form [elementDims x nElements x nSubGroups],
%    so the shortcut form is used only while no array has more dimensions
%    than its level. It is not used when ElementsPerSubGroup is given.
%  - structFields - The field names of struct rows, in the order of the
%    first struct row. It is {} when no row is a struct.
%  - elementsPerSubGroup - The value of ElementsPerSubGroup for the row
%    that is being flattened. flattenRows sets it for each row. It is []
%    when the option is not given.

    findings = struct('maxNumElementDims', -Inf, 'shortcutAllowed', true, ...
        'firstArray', [], 'firstArrayLevel', 0, ...
        'firstEmptyArray', [], 'firstEmptyArrayLevel', 0, ...
        'elementClass', "", 'structFields', {{}}, 'hasTextOrStructOrObject', false);
    for iRow = 1:numel(rows)
        findings = inspectGroup(rows{iRow}, depth, depth == 1, findings, iRow);
    end

    layout = struct('elementDims', [], 'useShortcut', false, ...
        'structFields', {findings.structFields}, 'elementsPerSubGroup', []);
    if findings.hasTextOrStructOrObject
        % Rows of strings, characters, structs or objects have no element
        % shape.
        return
    end
    shapeArray = findings.firstArray;
    shapeArrayLevel = findings.firstArrayLevel;
    if isempty(shapeArray)
        if findings.firstEmptyArrayLevel == 0
            return
        end
        shapeArray = findings.firstEmptyArray;
        shapeArrayLevel = findings.firstEmptyArrayLevel;
    end
    useShortcut = ~hasElementsPerSubGroup && depth >= 2 ...
        && findings.shortcutAllowed && findings.maxNumElementDims <= 1;
    if useShortcut
        numElementDims = 1;
    elseif hasElementsPerSubGroup
        % A [elementDims x nElements] row shows one dimension fewer than the
        % full form, so a column of such rows shows no element dimension.
        % Elements have at least one.
        numElementDims = max(findings.maxNumElementDims, 1);
    else
        numElementDims = findings.maxNumElementDims;
    end
    elementDims = splitDims(shapeArray, shapeArrayLevel, numElementDims, useShortcut);
    if any(elementDims == 0)
        % The array is empty along an element dimension, so it declares no
        % elements or sub-groups to count.
        return
    end
    layout.useShortcut = useShortcut;
    layout.elementDims = elementDims;
end

function findings = inspectGroup(group, level, vectorsAreScalarLists, findings, position)
% inspectGroup - Record what one row or sub-group shows about the class and size of the elements.
%
% inferLayout calls this function for every row before any data is
% copied. The function records the facts that the layout is derived from,
% and raises an error when rows cannot be combined in one column: rows of
% different classes, or struct rows with different fields. For a cell
% array of sub-groups, the function calls itself for each sub-group.
%
% The findings are a struct with the fields:
%  - maxNumElementDims - The largest number of element dimensions that
%    any numeric array shows. It is -Inf until an array shows one.
%  - shortcutAllowed - True until the numeric array of a group of level 2
%    or higher has more dimensions than its level. Such an array is not
%    in the shortcut form.
%  - firstArray - The first numeric array that is not empty and not a
%    list of scalars. Its leading dimensions give the size of one element.
%    It is [] until such an array is found.
%  - firstArrayLevel - The level of the group that firstArray was given
%    for.
%  - firstEmptyArray - The first empty array that declares sub-groups,
%    such as [k x 0 x n]. It gives the size of one element when no row
%    holds an element.
%  - firstEmptyArrayLevel - The level of the group that firstEmptyArray
%    was given for. It is 0 until such an array is found.
%  - elementClass - The class of the elements, such as "double". It is
%    an empty string until a row holds an element.
%  - structFields - The field names of the first struct row. It is {}
%    until a struct row is found.
%  - hasTextOrStructOrObject - True when a row holds strings, characters,
%    structs or objects.
%
% Input arguments:
%  - group - The row or sub-group, as it was given in data.
%  - level - The level of the group.
%  - vectorsAreScalarLists - True when a numeric vector is a list of
%    scalar elements, which is the case for the rows of a column of depth
%    1. Such a vector shows no element dimensions.
%  - findings - The findings of the groups inspected so far.
%  - position - The position of the group, used in error messages.

    if level == 1 && isTextOrStructOrObject(group)
        if ~isempty(group)
            findings.hasTextOrStructOrObject = true;
            findings = recordElementClass(findings, group, position);
        end
        if isstruct(group) && ~isempty(group)
            if isempty(findings.structFields)
                findings.structFields = fieldnames(group);
            elseif ~isequal(sort(fieldnames(group)), sort(findings.structFields))
                error("NWB:CreateIndexedColumn:InconsistentElementShape", ...
                    "All struct rows must have the same fields. %s has fields {%s}, " + ...
                    "but an earlier row has {%s}.", formatPosition(position), ...
                    strjoin(fieldnames(group), ", "), strjoin(findings.structFields, ", "));
            end
        end
        return
    end
    if iscell(group)
        % A cell array at level 1 is rejected by flattenGroup.
        if level >= 2
            for iSubGroup = 1:numel(group)
                findings = inspectGroup(group{iSubGroup}, level-1, false, findings, [position, iSubGroup]);
            end
        end
        return
    end
    if ~(isnumeric(group) || islogical(group))
        return
    end
    if ~isempty(group)
        findings = recordElementClass(findings, group, position);
    end
    if level == 1 && isempty(group)
        % An innermost group without elements declares no element shape,
        % whatever its size.
        return
    end
    if vectorsAreScalarLists && isvector(group)
        return
    end

    numDims = ndims(group);
    findings.maxNumElementDims = max(findings.maxNumElementDims, numDims-level);
    if level >= 2 && numDims > level
        findings.shortcutAllowed = false;
    end
    % The first non-empty array supplies the element shape. An empty array that
    % declares sub-groups, such as [k x 0 x n], supplies it when no row holds
    % an element.
    if isempty(findings.firstArray) && ~isempty(group)
        findings.firstArray = group;
        findings.firstArrayLevel = level;
    elseif isempty(group) && level >= 2 && ~ismatrix(group) && findings.firstEmptyArrayLevel == 0
        findings.firstEmptyArray = group;
        findings.firstEmptyArrayLevel = level;
    end
end

function joined = concatenateElements(elementArrays, layout)
% concatenateElements - Join the element arrays of several groups along the last dimension.
%
% Empty arrays are left out before joining, so a group with no elements
% can be given as an empty array of any size.

    nonEmptyArrays = elementArrays(~cellfun(@isempty, elementArrays));
    if isempty(nonEmptyArrays)
        joined = [];
        return
    end
    joined = cat(numel(layout.elementDims)+1, nonEmptyArrays{:});
end

function findings = recordElementClass(findings, group, position)
% recordElementClass - Record the class of the elements of a group, and reject a class that differs from earlier groups.
%
% Rows of different classes are not combined, because joining them would
% convert the values of one class to the other.

    groupClass = string(class(group));
    if findings.elementClass == ""
        findings.elementClass = groupClass;
    elseif groupClass ~= findings.elementClass
        error("NWB:CreateIndexedColumn:InconsistentElementType", ...
            "%s must hold %s elements like the other rows of the column. " + ...
            "It holds %s elements.", formatPosition(position), findings.elementClass, groupClass);
    end
end

function tf = isTextOrStructOrObject(value)
% isTextOrStructOrObject - Return true for a string array, character vector, struct array or array of objects.
%
% Such a value holds one element per string, character, struct or object.
% A numeric array is instead split into elements by its dimensions.

    tf = isstring(value) || ischar(value) || isstruct(value) || isObjectArray(value);
end

function tf = isObjectArray(value)
% isObjectArray - Return true for an array of objects, such as types.untyped.ObjectView references.
%
% A table is an object too, but its rows are not elements of one class.

    tf = isobject(value) && ~istable(value);
end

function hint = cellFormHint(level)
% cellFormHint - Return the part of an error message that names the cell form of a row.
%
% A row can be a cell array of sub-groups only above level 1, so the text
% is empty for a group of level 1.

    if level > 1
        hint = ' or a cell array of sub-groups';
    else
        hint = '';
    end
end

function label = formatPosition(position)
% formatPosition - Return the position of a group as text for an error message.
%
% The text is 'data{3}{2}' for the position [3 2], and 'data' for an
% empty position, which stands for data itself. Callers pass the position
% as numbers and format it only when they raise an error, because a
% column can hold millions of groups.

    label = 'data';
    if ~isempty(position)
        label = [label, sprintf('{%d}', position)];
    end
end
