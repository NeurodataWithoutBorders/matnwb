function vectorIndexName = addVecInd(dynamicTable, columnName)
%ADDVECIND Add VectorIndex object to DynamicTable
    arguments
        dynamicTable (1,1) {matnwb.common.validation.mustBeDynamicTable}
        columnName {mustBeTextScalar}
    end

    columnName = char(columnName);
    vectorIndexName = [columnName '_index']; % arbitrary convention of appending '_index' to data column names
    
    if isprop(dynamicTable, columnName)
        vectorData = dynamicTable.(columnName);
    elseif isprop(dynamicTable, 'vectorindex') && isKey(dynamicTable.vectorindex, columnName)
        vectorData = dynamicTable.vectorindex.get(columnName);
    else
        vectorData = dynamicTable.vectordata.get(columnName);
    end
    
    if isa(vectorData.data, 'types.untyped.DataPipe')
        oldDataHeight = vectorData.data.offset;
    elseif isa(vectorData.data, 'types.untyped.DataStub')
        oldDataHeight = vectorData.data.dims(end);
    elseif isvector(vectorData.data)
        oldDataHeight = length(vectorData.data);
    else
        oldDataHeight = size(vectorData.data, ndims(vectorData.data));
    end
    
    % we presume that if data already existed in the vectordata, then
    % it was never a ragged array and thus its elements corresponded
    % directly to each row index.
    vectorView = types.untyped.ObjectView(vectorData);
    if 8 == exist('types.hdmf_common.VectorIndex', 'class')
        vectorIndex = types.hdmf_common.VectorIndex('target', vectorView, 'data', (1:oldDataHeight) .');
    else
        vectorIndex = types.core.VectorIndex('target', vectorView, 'data', (1:oldDataHeight) .');
    end
    
    if isprop(vectorIndex, 'description')
        vectorIndex.description = sprintf('Index into column %s', columnName);
    end
    
    if isprop(dynamicTable, vectorIndexName)
        dynamicTable.(vectorIndexName) = vectorIndex;
    elseif isprop(dynamicTable, 'vectorindex')
        dynamicTable.vectorindex.set(vectorIndexName, vectorIndex);
    else
        dynamicTable.vectordata.set(vectorIndexName, vectorIndex);
    end
end
