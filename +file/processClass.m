function [Processed, classprops, inherited] = processClass(name, namespace, pregen)
    inherited = {};
    branch = [{namespace.getClass(name)} namespace.getRootBranch(name)];
    branchNames = cell(size(branch));
    TYPEDEF_KEYS = {'neurodata_type_def', 'data_type_def'};

    for i = 1:length(branch)
        hasTypeDefs = isKey(branch{i}, TYPEDEF_KEYS);
        branchNames{i} = branch{i}(TYPEDEF_KEYS{hasTypeDefs});
    end

    for iAncestor = 1:length(branch)
        node = branch{iAncestor};
        hasTypeDefs = isKey(node, TYPEDEF_KEYS);
        nodename = node(TYPEDEF_KEYS{hasTypeDefs});

        if ~isKey(pregen, nodename)

            spec.internal.resolveInheritedFields(node, branch(iAncestor+1:end))
            spec.internal.expandFieldsInheritedByInclusion(node)
            
            switch node('class_type')
                case 'groups'
                    class = file.Group(node);
                case 'datasets'
                    class = file.Dataset(node);
                otherwise
                    error('NWB:FileGen:InvalidClassType',...
                        'Class type %s is invalid', node('class_type'));
            end

            props = class.getProps();
            props = markPromotedAttributesForIncludedTypedDatasets(class, props, namespace);

            % Apply patches for special cases of schema/specification errors
            class = applySchemaVersionPatches(nodename, class, props, namespace);

            pregen(nodename) = struct('class', class, 'props', props);
        end
        try
            Processed(iAncestor) = pregen(nodename).class;
        catch
            keyboard;
        end
    end
    classprops = pregen(name).props;
    names = keys(classprops);
    for iAncestor = 2:length(Processed)
        pname = Processed(iAncestor).type;
        parentPropNames = keys(pregen(pname).props);
        inherited = union(inherited, intersect(names, parentPropNames));
    end
end

function props = markPromotedAttributesForIncludedTypedDatasets(classObj, props, namespace)
    if ~isa(classObj, 'file.Group') || isempty(classObj.datasets)
        return;
    end

    for iDataset = 1:length(classObj.datasets)
        datasetObj = classObj.datasets(iDataset);
        if isempty(datasetObj.type) || isempty(datasetObj.name) || isempty(datasetObj.attributes)
            continue;
        end

        datasetNamespace = namespace.getNamespace(datasetObj.type);
        if isempty(datasetNamespace)
            continue;
        end

        schemaAttributeNames = getSchemaDefinedAttributeNames(datasetObj.type, datasetNamespace);
        for iAttr = 1:length(datasetObj.attributes)
            attribute = datasetObj.attributes(iAttr);
            propertyName = [datasetObj.name '_' attribute.name];
            if ~isKey(props, propertyName)
                continue;
            end

            if any(strcmp(attribute.name, schemaAttributeNames))
                remove(props, propertyName);
            else
                promotedAttribute = props(propertyName);
                promotedAttribute.promoted_to_container = true;
                props(propertyName) = promotedAttribute;
            end
        end
    end
end

function attributeNames = getSchemaDefinedAttributeNames(typeName, namespace)
    persistent schemaAttributeNameCache

    if isempty(schemaAttributeNameCache)
        schemaAttributeNameCache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end

    cacheKey = strjoin({namespace.name, namespace.version, typeName}, '::');
    if isKey(schemaAttributeNameCache, cacheKey)
        attributeNames = schemaAttributeNameCache(cacheKey);
        return;
    end

    typeSpec = namespace.getClass(typeName);
    if isempty(typeSpec)
        attributeNames = {};
        return;
    end

    branch = [{typeSpec} namespace.getRootBranch(typeName)];
    spec.internal.resolveInheritedFields(typeSpec, branch(2:end))
    spec.internal.expandFieldsInheritedByInclusion(typeSpec)

    switch typeSpec('class_type')
        case 'groups'
            classObj = file.Group(typeSpec);
        case 'datasets'
            classObj = file.Dataset(typeSpec);
        otherwise
            attributeNames = {};
            return;
    end

    typeProps = classObj.getProps();
    propNames = keys(typeProps);
    isAttribute = cellfun(@(name) isa(typeProps(name), 'file.Attribute'), propNames);
    attributeNames = propNames(isAttribute);
    schemaAttributeNameCache(cacheKey) = attributeNames;
end
