function propertyNames = getEagerLoadPropsForClass(fullClassName, namespace)
% getEagerLoadPropsForClass - List generated eager-load properties for a type.

    arguments
        fullClassName (1,1) string
        namespace schemes.Namespace = schemes.Namespace.empty
    end

    if strcmp(fullClassName, 'NwbFile')
        superclassNames = string(superclasses(fullClassName));
        fullClassName = superclassNames(endsWith(superclassNames, 'NWBFile'));
    end

    classNameSplit = strsplit(fullClassName, '.');
    className = classNameSplit(end);
    if isempty(namespace)
        namespaceName = classNameSplit(find(strcmp(classNameSplit, 'types'))+1);
        namespaceName = strrep(namespaceName, '_', '-');
        namespace = schemes.loadNamespace(namespaceName);
    end

    processedTypeMap = containers.Map;
    [processed, classProps, ~] = file.processClass(className, namespace, processedTypeMap);
    if isempty(processed)
        propertyNames = {};
        return
    end

    superClassProps = cell(1, numel(processed)-1);
    for iSuper = 2:numel(processed)
        [~, superClassProps{iSuper-1}, ~] = file.processClass(processed(iSuper).type, namespace, processedTypeMap);
    end
    classProps = file.internal.mergeProps(classProps, superClassProps);

    propertyNames = file.getEagerLoadPropertyNames(processed(1), classProps);
end
