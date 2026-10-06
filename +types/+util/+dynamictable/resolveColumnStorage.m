function [storageTarget, storageName] = resolveColumnStorage(dynamicTable, columnName)
%resolveColumnStorage - Determine where an added column should be stored.
% Schema-backed table columns are stored on the object property itself.
% All other columns are stored in the generic vectordata set.

    arguments
        dynamicTable {matnwb.common.validation.mustBeDynamicTable}
        columnName (1,1) string
    end

    storageName = char(columnName);
    schemaNameMapping = io.internal.getSchemaPropertyNameMapping(dynamicTable);
    propertyName = io.internal.getPropertyNameForSchemaName( ...
        schemaNameMapping, storageName);

    if dynamicTable.isDynamicProperty(columnName)
        storageTarget = 'vectordata';
        return
    end

    schemaColumnNames = dynamicTable.getSchemaDefinedColumns();
    if any(schemaColumnNames == columnName)
        storageName = propertyName;
        storageTarget = 'property';
        return
    end

    if isprop(dynamicTable, propertyName)
        newException = MException('NWB:DynamicTable:AddColumn:InvalidPropertyCollision', ...
            ['Cannot add column `%s` because it collides with non-column property ' ...
             '`%s` on `%s`.'], ...
            columnName, columnName, class(dynamicTable));
        throwAsCaller(newException)
    end

    storageTarget = 'vectordata';
end
