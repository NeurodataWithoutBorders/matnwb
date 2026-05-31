function typeMap = getTypeMap(dynamicTable)
% GETTYPEMAP returns containers.Map mapping column name to struct
% containing type name and size.
    arguments
        dynamicTable (1,1) {matnwb.common.validation.mustBeDynamicTable}
    end

    typeMap = containers.Map;
    if isempty(dynamicTable.id.data)...
            || (isa(dynamicTable.id.data, 'types.untyped.DataPipe')...
                && 0 == dynamicTable.id.data.offset)
        return;
    end
    typeInfo = struct('type', '', 'dims', [0, 0]);
    for iColumn = 1:length(dynamicTable.colnames)
        columnName = dynamicTable.colnames{iColumn};
        if isprop(dynamicTable, columnName)
            columnVectorData = dynamicTable.(columnName);
        else
            columnVectorData = dynamicTable.vectordata.get(columnName);
        end
    
        if isa(columnVectorData.data, 'types.untyped.DataPipe')
            columnValue = columnVectorData.data.load(1);
        elseif istable(columnVectorData.data)
            columnValue = columnVectorData.data;
        else
            columnValue = columnVectorData.data(1);
        end
    
        if iscellstr(columnValue)
            typeInfo.type = 'cellstr';
        else
            typeInfo.type = class(columnValue);
        end
    
        if isa(columnVectorData.data, 'types.untyped.DataPipe')
            typeInfo.dims = columnVectorData.data.internal.maxSize;
        else
            typeInfo.dims = size(columnVectorData.data);
        end
    
        typeMap(columnName) = typeInfo;
    end
end
