function requiredPropertyNames = getRequiredPropsForClass(fullClassName, namespace)
% getRequiredPropsForClass - List required properties for a neurodata type / class

    arguments
        fullClassName (1,1) string % E.g types.core.TimeSeries
        namespace schemes.Namespace = schemes.Namespace.empty
    end

    % For the NwbFile class, we need to replace it with the generated
    % NWBFile superclass in order to retrieve schema information correctly
    if strcmp(fullClassName, 'NwbFile')
        superclassNames = string(superclasses(fullClassName));
        fullClassName = superclassNames(endsWith(superclassNames, 'NWBFile'));
    end

    % Load cached namespace specifications
    classNameSplit = strsplit(fullClassName, '.');
    className = classNameSplit(end);
    if isempty(namespace)
        namespaceName = classNameSplit(find(strcmp(classNameSplit, 'types'))+1);
        namespaceName = strrep(namespaceName, '_', '-');
        namespace = schemes.loadNamespace(namespaceName);
    end
   
    % Process/parse the namespace specifications to retrieve attributes for
    % the class properties.
    processedTypeMap = containers.Map;
    [processed, classprops, ~] = file.processClass(className, namespace, processedTypeMap);
    if ~isempty(processed)
        superClassProps = cell(1, numel(processed)-1);
        for iSuper = 2:numel(processed)
            [~, superClassProps{iSuper-1}, ~] =  file.processClass(processed(iSuper).type, namespace, processedTypeMap);
        end
        classprops = file.internal.mergeProps(classprops, superClassProps);
    end
    
    % Resolve the required properties. For the final list of required properties,
    % we ignore both hidden and read-only properties.
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
