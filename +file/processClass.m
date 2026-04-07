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
            if strcmp(nodename, 'VectorData') && strcmp(namespace.name, 'hdmf_common')
                class = patchVectorData(class);
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

function class = patchVectorData(class)
    %% Unit Attribute
    % derived from schema 2.6.0
    source = containers.Map();
    source('name') = 'unit';
    source('doc') = ['NOTE: this is a special value for compatibility with the Units table and is ' ...
        'only written to file when detected to be in that specific HDF5 Group. ' ...
        'The value must be ''volts'''];
    source('dtype') = 'text';
    source('value') = 'volts';
    source('required') = false;
    class.attributes(end+1) = file.Attribute(source);

    %% Sampling Rate Attribute
    % derived from schema 2.6.0

    source = containers.Map();
    source('name') = 'sampling_rate';
    source('doc') = ['NOTE: this is a special value for compatibility with the Units table and is ' ...
        'only written to file when detected to be in that specific HDF5 Group. ' ...
        'Must be Hertz'];
    source('dtype') = 'float32';
    source('required') = false;

    class.attributes(end+1) = file.Attribute(source);
    %% Resolution Attribute
    % derived from schema 2.6.0

    source = containers.Map();
    source('name') = 'resolution';
    source('doc') = ['NOTE: this is a special value for compatibility with the Units table and is ' ...
        'only written to file when detected to be in that specific HDF5 Group. ' ...
        'The smallest possible difference between two spike times. ' ...
        'Usually 1 divided by the acquisition sampling rate from which spike times were extracted, ' ...
        'but could be larger if the acquisition time series was downsampled or smaller if the ' ...
        'acquisition time series was smoothed/interpolated ' ...
        'and it is possible for the spike time to be between samples.' ...
        ];
    source('dtype') = 'float64';
    source('required') = false;

    class.attributes(end+1) = file.Attribute(source);
end
