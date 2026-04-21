function indexName = getIndex(dynamicTable, columnName)
%GETINDEX Given a dynamic table and its column name, get its VectorIndex column name
    arguments
        dynamicTable (1,1) {matnwb.common.validation.mustBeDynamicTable}
        columnName {mustBeTextScalar}
    end

    columnName = char(columnName);
    indexName = '';
    if strcmp(columnName, 'id')
        return;
    end
    
    % after Schema version 2.3.0, VectorIndex objects subclass VectorData which
    % meant that vectorindex and vectordata sets could be combined.
    isLegacyDynamicTable = isprop(dynamicTable, 'vectorindex');
    if isLegacyDynamicTable
        vectorKeys = keys(dynamicTable.vectorindex);
    else
        vectorKeys = keys(dynamicTable.vectordata);
    end
    for iKey = 1:length(vectorKeys)
        vectorKey = vectorKeys{iKey};
        if isLegacyDynamicTable
            vectorData = dynamicTable.vectorindex.get(vectorKey);
        else
            vectorData = dynamicTable.vectordata.get(vectorKey);
        end
        if ~isa(vectorData, 'types.hdmf_common.VectorIndex')...
                && ~isa(vectorData, 'types.core.VectorIndex')
            continue;
        end
        if isVecIndColumn(dynamicTable, vectorData, columnName)
            indexName = vectorKey;
            return;
        end
    end
    
    % check if dynamic table object has extended properties which point to
    % vector indices. These are specifically defined by the schema to be
    % properties.
    dynamicTableProps = properties(dynamicTable);
    isPropertyVectorIndex = false(size(dynamicTableProps));
    for iProp = 1:length(dynamicTableProps)
        propertyValue = dynamicTable.(dynamicTableProps{iProp});
        isPropertyVectorIndex(iProp) = isa(propertyValue, 'types.hdmf_common.VectorIndex')...
            || isa(propertyValue, 'types.core.VectorIndex');
    end
    
    dynamicTableProps = dynamicTableProps(isPropertyVectorIndex);
    for iProp = 1:length(dynamicTableProps)
        vectorKey = dynamicTableProps{iProp};
        vectorIndex = dynamicTable.(vectorKey);
        if isVecIndColumn(dynamicTable, vectorIndex, columnName)
            indexName = vectorKey;
            return;
        end
    end
end

function tf = isVecIndColumn(dynamicTable, vectorIndex, columnName)
    arguments
        dynamicTable (1,1) {matnwb.common.validation.mustBeDynamicTable}
        vectorIndex
        columnName (1,:) char
    end

    if vectorIndex.target.has_path()
        tf = endsWith(vectorIndex.target.path, ['/' columnName]);
    elseif isprop(dynamicTable, columnName)
        tf = vectorIndex.target.target == dynamicTable.(columnName);
    else
        if isprop(dynamicTable, 'vectorindex') && dynamicTable.vectorindex.isKey(columnName)
            vectorData = dynamicTable.vectorindex.get(columnName);
        else
            vectorData = dynamicTable.vectordata.get(columnName);
        end
        tf = vectorIndex.target.target == vectorData;
    end
end
