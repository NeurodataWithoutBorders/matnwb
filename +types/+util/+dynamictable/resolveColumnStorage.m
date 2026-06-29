function storageTarget = resolveColumnStorage(dynamicTable, columnName, columnData)
%resolveColumnStorage - Determine where an added column should be stored.
% Schema-backed table columns are stored on the object property itself.
% All other columns are stored in the generic vectordata set.

    arguments
        dynamicTable {matnwb.common.validation.mustBeDynamicTable}
        columnName (1,1) string
        columnData {matnwb.common.validation.mustBeVectorData}
    end

    if ~isprop(dynamicTable, columnName)
        storageTarget = 'vectordata';
        return;
    end

   
    if canAssignToProperty(dynamicTable, columnName, columnData)
        storageTarget = 'property';
        return;
    end

    if ~isSchemaColumnProperty(dynamicTable, columnName)
        newException = MException('NWB:DynamicTable:AddColumn:InvalidPropertyCollision', ...
            ['Cannot add column `%s` because it collides with non-column property ' ...
             '`%s` on `%s`.'], ...
            columnName, columnName, class(dynamicTable));
        throwAsCaller(newException)
    end

    storageTarget = 'property';
end

function tf = canAssignToProperty(dynamicTable, columnName, columnData)
    dummyTable = feval(class(dynamicTable));
    dummyColumn = feval(class(columnData));
    tf = tryAssignToProperty(dummyTable, columnName, dummyColumn);
end

function tf = isSchemaColumnProperty(dynamicTable, columnName)
    dummyTable = feval(class(dynamicTable));
    dummyColumns = getDummyColumnObjects();

    tf = false;
    for i = 1:length(dummyColumns)
        if tryAssignToProperty(dummyTable, columnName, dummyColumns{i})
            tf = true;
            return;
        end
    end
end

function tf = tryAssignToProperty(dynamicTable, columnName, columnData)
    tf = false;
    try
        dynamicTable.(columnName) = columnData;
        tf = true;
    catch
        % Assignment failed, so this value is not accepted for the property.
    end
end

function dummyColumns = getDummyColumnObjects()
    dummyColumns = {
        types.hdmf_common.VectorData()
        types.hdmf_common.VectorIndex()
        types.hdmf_common.DynamicTableRegion()
    };

    if exist('types.core.TimeSeriesReferenceVectorData', 'class')
        dummyColumns{end+1} = types.core.TimeSeriesReferenceVectorData();
    end
end
