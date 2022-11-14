function TypeMap = getTypeMap(DynamicTable)
% GETTYPEMAP returns containers.Map mapping column name to struct
% containing type name and size.
TypeMap = containers.Map;
if isempty(DynamicTable.id.data)...
        || (isa(DynamicTable.id.data, 'types.untyped.DataPipe')...
            && 0 == DynamicTable.id.data.offset)
    return;
end
TypeStruct = struct('type', '', 'dims', [0, 0]);
for i = 1:length(DynamicTable.colnames)
    colnm = DynamicTable.colnames{i};
    if isprop(DynamicTable, colnm)
        colVecData = DynamicTable.(colnm);
    else
        colVecData = DynamicTable.vectordata.get(colnm);
    end

    if isa(colVecData.data, 'types.untyped.DataPipe')
        colval = colVecData.data.load(1);
    elseif istable(colVecData.data)
        colval = colVecData.data;
    else
        colval = colVecData.data(1);
    end
    
    if iscellstr(colval)
        TypeStruct.type = 'cellstr';
    else
        TypeStruct.type = class(colval);
    end
    
    if isa(colVecData.data, 'types.untyped.DataPipe')
        TypeStruct.dims = colVecData.data.internal.maxSize;
    else
        TypeStruct.dims = size(colVecData.data);
    end
    
    TypeMap(colnm) = TypeStruct;
end
end

