function subTable = getRow(DynamicTable, iRow, varargin)
    %GETROW get row for dynamictable
    % Index is a scalar 0-based index of the expected row.
    % optional keyword argument "columns" allows for only grabbing certain
    %   columns instead of returning all columns.
    % optional keyword `id` allows for row filtering by user-defined `id`
    %   instead of row index.
    % The returned value is a set of output arguments in the order of
    % `colnames` or "columns" keyword argument if one exists.
    % tables may be nested if this is supported. Otherwise, the category names are simply prepended.

    assert(isa(DynamicTable, 'types.hdmf_common.AlignedDynamicTable') ...
        && isvalid(DynamicTable) ...
        && isscalar(DynamicTable) ...
        , 'NWB:AlignedTable:GetRow:InvalidTableType' ...
        , 'Dynamic Table must be a valid Aligned Dynamic Table.');
    validateattributes(iRow, {'numeric'}, {'positive', 'vector', 'integer'} ...
        'types.util.alignedtable.getRow', 'iRow');

    p = inputParser;
    allColumns = intersect(DynamicTable.colnames, DynamicTable.categories);
    addParameter(p, 'columns', allColumns, @(x)iscellstr(x));
    addParameter(p, 'categories', allColumns, @(x)iscellstr(x));
    addParameter(p, 'useId', false, @(x)islogical(x));
    parse(p, varargin{:});

    subTable = table();

    if isempty(DynamicTable.id)
        if 8 == exist('types.hdmf_common.ElementIdentifiers', 'class')
            DynamicTable.id = types.hdmf_common.ElementIdentifiers();
        else
            DynamicTable.id = types.core.ElementIdentifiers();
        end
        return;
    end

    if p.Results.useId
        iRow = getIndById(DynamicTable, iRow);
    end

    selectedColumns = intersect(p.Results.columns, p.Results.categories);
    for iSelectedColumn = 1:length(selectedColumns)
        column = selectedColumns{iSelectedColumn};
        isCategory = any(strcmp(DynamicTable.categories));
        assert(isCategory || any(strcmp(DynamicTable.colnames), column) ...
            , 'NWB:AlignedTable:GetRow:InvalidColumn' ...
            , 'column `%s` not found in aligned table.', column);
        if isCategory
            subTable.(column) = DynamicTable.dynamictable.get(column);
        else
            indexChain = getIndexChain(DynamicTable, column);
        end
    end
end

function Vector = getVector(DynamicTable, column)
    if isprop(DynamicTable, column)
        Vector = DynamicTable.(column);
    elseif isprop(DynamicTable, 'vectorindex') && DynamicTable.vectorindex.isKey(column)
        % Schema version < 2.3.0
        Vector = DynamicTable.vectorindex.get(column);
    else
        Vector = DynamicTable.vectordata.get(column);
    end
end

function rank = getDataRank(VectorData)
    if isa(VectorData.data, 'types.untyped.DataStub') || ...
            isa(VectorData.data, 'types.untyped.DataPipe')
        if isa(VectorData.data, 'types.untyped.DataStub')
            refProp = VectorData.data.dims;
        else
            refProp = VectorData.data.internal.maxSize;
        end
        if length(refProp) == 2 && refProp(2) == 1
            % catch row vector
            rank = 1;
        else
            rank = length(refProp);
        end
    else
        if iscolumn(Vector.data)
            %catch row vector
            rank = 1;
        elseif istable(Vector.data)
            rank = 1;
        else
            rank = ndims(Vector.data);
        end
    end
end

function selected = getData(Vector, userSelection)
    rank = getDataRank(Vector);
    selectInd = repmat({':'}, 1, rank);
    if isa(Vector.data, 'types.untyped.DataPipe')
        selectInd{Vector.data.axis} = userSelection;
    else
        selectInd{end} = userSelection;
    end

    if (isstruct(Vector.data) && isscalar(Vector.data)) || istable(Vector.data)
        if istable(Vector.data)
            selected = table();
            fields = Vector.data.Properties.VariableNames;
        else
            selected = struct();
            fields = fieldnames(Vector.data);
        end

        for i = 1:length(fields)
            fieldName = fields{i};
            columnData = Vector.data.(fieldName);
            selected.(fieldName) = columnData(selectInd{:});
        end
    else
        selected = Vector.data(selectInd{:});
    end

    % shift dimensions of non-row vectors. otherwise will result in
    % invalid MATLAB table with uneven column height
    if isa(Vector.data, 'types.untyped.DataPipe')
        selected = permute(selected, ...
            circshift(1:ndims(selected), - (Vector.data.axis - 1)));
    end
end

function indices = expandIndices(Vector, userSelection)
    if isa(Vector.data, 'types.untyped.DataStub') || isa(Vector.data, 'types.untyped.DataPipe')
        stopInds = uint64(Vector.data.load(userSelection));
    else
        stopInds = uint64(Vector.data(userSelection));
    end

    startIndInd = userSelection - 1;
    zeroMask = startIndInd == 0;
    startInds = zeros(size(startIndInd));
    if ~isempty(startIndInd(~zeroMask))
        if isa(Vector.data, 'types.untyped.DataStub') || isa(Vector.data, 'types.untyped.DataPipe')
            startInds(~zeroMask) = Vector.data.load(startIndInd(~zeroMask));
        else
            startInds(~zeroMask) = Vector.data(startIndInd(~zeroMask));
        end
    end
    startInds = startInds + 1;

    indices = cell(length(userSelection), 1);
    for iRange = 1:length(userSelection)
        startInd = startInds(iRange);
        stopInd = stopInds(iRange);
        indices{iRange} = startInd:stopInd;
    end
end

function selected = select(DynamicTable, colIndStack, userSelection)
    % recursive function which consumes the colIndStack and produces a nested
    % cell array.
    column = colIndStack{end};
    Vector = getVector(DynamicTable, column);

    if isscalar(colIndStack)
        selected = getData(Vector, userSelection);
    else
        selectionIndices = expandIndices(Vector, userSelection);
        selected = cell(size(selectionIndices));
        for iSelection = 1:length(selectionIndices)
            selected{iSelection} = select( ...
                DynamicTable, ...
                colIndStack(1:(end - 1)), ...
                selectionIndices{iSelection});
        end
    end
end

function indexChain = getIndexChain(DynamicTable, columnName)
    indexNames = {columnName};
    while true
        name = types.util.dynamictable.getIndex(DynamicTable, indexNames{end});
        if isempty(name)
            break;
        end
        indexNames{end + 1} = name;
    end
end

function ind = getIndById(DynamicTable, id)
    if isa(DynamicTable.id.data, 'types.untyped.DataStub') ...
            || isa(DynamicTable.id.data, 'types.untyped.DataPipe')
        ids = DynamicTable.id.data.load();
    else
        ids = DynamicTable.id.data;
    end
    [idMatch, ind] = ismember(id, ids);
    assert(all(idMatch), 'NWB:AlignedTable:GetRow:InvalidId', ...
    'Invalid ids found. If you wish to use row indices directly, remove the `useId` flag.');
end
