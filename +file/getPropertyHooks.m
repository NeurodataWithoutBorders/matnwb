function hooks = getPropertyHooks(propName, prop, typeName, namespace)
%GETPROPERTYHOOKS Return custom generator hooks for property validators/setters.

    hooks = struct( ...
        'ValidatorLines', {{}}, ...
        'PostsetStatements', {{}});

    fullClassName = namespace.getFullClassName(typeName);

    if strcmp(typeName, 'DynamicTable') && strcmp(propName, 'colnames')
        hooks.ValidatorLines = { ...
            'val = types.util.dynamictable.validateColnames(val);' };
    end

    if strcmp(fullClassName, 'types.hdmf_common.AlignedDynamicTable') ...
            && strcmp(propName, 'categories')
        hooks.ValidatorLines = { ...
            'val = obj.validateCategoryNames(val);' };
    end

    isNamedTableColumn = file.internal.isDescendantOf(typeName, namespace, 'DynamicTable') ...
        && file.internal.isSchemaDefinedTableColumn(prop, namespace) ...
        && ~endsWith(propName, '_index');
    if isNamedTableColumn
        hooks.PostsetStatements = { ...
            sprintf('types.util.dynamictable.syncNamedColumn(obj, ''%s'');', propName) };
    end

    if file.internal.isDescendantOf(typeName, namespace, 'AlignedDynamicTable') ...
            && file.internal.isSchemaDefinedTableCategory(prop, namespace)
        hooks.PostsetStatements = [hooks.PostsetStatements, { ...
            sprintf('obj.ensureCategoryNameRegistered(''%s'');', propName) }];
    end
end
