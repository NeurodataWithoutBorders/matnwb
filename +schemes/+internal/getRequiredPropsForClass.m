function requiredPropertyNames = getRequiredPropsForClass(fullClassName)
    arguments
        fullClassName (1,1) string
    end

    if strcmp(fullClassName, 'NwbFile')
        superclassNames = string(superclasses(fullClassName));
        fullClassName = superclassNames(endsWith(superclassNames, 'NWBFile'));
    end

    classNameSplit = strsplit(fullClassName, '.');
    className = classNameSplit(end);
    namespaceName = classNameSplit(find(strcmp(classNameSplit, 'types'))+1);
    namespaceName = strrep(namespaceName, '_', '-');
    namespace = schemes.loadNamespace(namespaceName);
   
    [~, classprops, ~] = file.processClass(className, namespace, containers.Map);

    allPropertieNames = keys(classprops);
    [isRequired, isReadOnly, isHidden] = deal( false(1, classprops.Count) );
    
    for iProp = 1:length(allPropertieNames)
        propertyName = allPropertieNames{iProp};
        prop = classprops(propertyName);
        isRequired(iProp) = file.internal.isPropertyRequired(prop, propertyName, classprops);
        isReadOnly(iProp) = file.internal.isPropertyReadonly(prop);
        isHidden(iProp) = file.internal.isPropertyHidden(prop, className, namespace);
    end

    requiredPropertyNames = allPropertieNames(isRequired & ~isReadOnly & ~isHidden);
end
