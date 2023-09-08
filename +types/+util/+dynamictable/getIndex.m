function indexName = getIndex(DynamicTable, columnName)
    %GETINDEX Given a dynamic table and its column name, get its VectorIndex column name
    validateattributes(DynamicTable,...
        {'types.core.DynamicTable', 'types.hdmf_common.DynamicTable'},...
        {'scalar'});
    validateattributes(columnName, {'char'}, {'scalartext'});
    indexName = '';
    if strcmp(columnName, 'id')
        return;
    end

    % after Schema version 2.3.0, VectorIndex objects subclass VectorData which
    % meant that vectorindex and vectordata sets could be combined.
    isLegacyDynamicTable = isprop(DynamicTable, 'vectorindex');
    if isLegacyDynamicTable
        vectorKeys = keys(DynamicTable.vectorindex);
    else
        vectorKeys = keys(DynamicTable.vectordata);
    end
    for iKey = 1:length(vectorKeys)
        tableProperties = vectorKeys{iKey};
        if isLegacyDynamicTable
            Vector = DynamicTable.vectorindex.get(tableProperties);
        else
            Vector = DynamicTable.vectordata.get(tableProperties);
        end
        if ~isa(Vector, 'types.hdmf_common.VectorIndex') && ~isa(Vector, 'types.core.VectorIndex')
            continue;
        end
        if isVecIndColumn(DynamicTable, Vector, columnName)
            indexName = tableProperties;
            return;
        end
    end

    % check if dynamic table object has extended properties which point to
    % vector indices. These are specifically defined by the schema to be
    % properties.
    DynamicTableProps = properties(DynamicTable);
    isPropVecInd = false(size(DynamicTableProps));
    for i = 1:length(DynamicTableProps)
        PropVec = DynamicTable.(DynamicTableProps{i});
        isPropVecInd(i) = isa(PropVec, 'types.hdmf_common.VectorIndex')...
            || isa(PropVec, 'types.core.VectorIndex');
    end

    DynamicTableProps = DynamicTableProps(isPropVecInd);
    for i = 1:length(DynamicTableProps)
        tableProperties = DynamicTableProps{i};
        VecInd = DynamicTable.(tableProperties);
        if isVecIndColumn(DynamicTable, VecInd, columnName)
            indexName = tableProperties;
            return;
        end
    end
end

function tf = isVecIndColumn(DynamicTable, VectorIndex, column)
    if VectorIndex.target.has_path()
        tf = endsWith(VectorIndex.target.path, ['/' column]);
    elseif isprop(DynamicTable, column)
        tf = VectorIndex.target.target == DynamicTable.(column);
    else
        if isprop(DynamicTable, 'vectorindex') && DynamicTable.vectorindex.isKey(column)
            Vec = DynamicTable.vectorindex.get(column);
        else
            Vec = DynamicTable.vectordata.get(column);
        end
        tf = VectorIndex.target.target == Vec;
    end
end

