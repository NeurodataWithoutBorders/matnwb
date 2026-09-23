function path = traverseRaw(propertyName, RawClass)
% traverseRaw - Find the schema nodes leading to a flattened property.
%
% path = file.internal.traverseRaw(propertyName, RawClass) returns a cell
% array of the file.Attribute, file.Dataset, file.Group and file.Link nodes
% of RawClass that lead to propertyName, outermost first. A property of a
% nested untyped node is flattened into an underscore-joined name, so
% "data_unit" resolves to {<data Dataset>, <unit Attribute>}. The path is
% empty when propertyName is not defined by RawClass itself.
    path = {}; 

    if isa(RawClass, 'file.Dataset')
        if ~isempty(RawClass.attributes)
            matchesAttribute = strcmp({RawClass.attributes.name}, propertyName);
            path = {RawClass.attributes(matchesAttribute)};
        end
        return;
    end

    % probably a file.Group

    % get names of both subgroups and datasets
    subgroupNames = {};
    datasetNames = {};
    linkNames = {};
    attributeNames = {};

    if ~isempty(RawClass.attributes)
        attributeNames = {RawClass.attributes.name};
    end

    if ~isempty(RawClass.subgroups)
        subgroupNames = {RawClass.subgroups.name};
        lowerGroupTypes = lower({RawClass.subgroups.type});
        useLower = [RawClass.subgroups.isConstrainedSet] | cellfun('isempty', subgroupNames);
        subgroupNames(useLower) = lowerGroupTypes(useLower);
    end

    if ~isempty(RawClass.datasets)
        datasetNames = {RawClass.datasets.name};
        lowerDsTypes = lower({RawClass.datasets.type});
        useLower = [RawClass.datasets.isConstrainedSet] | cellfun('isempty', datasetNames);
        datasetNames(useLower) = lowerDsTypes(useLower);
    end

    if ~isempty(RawClass.links)
        linkNames = {RawClass.links.name};
    end

    if any(strcmp([attributeNames subgroupNames datasetNames linkNames], propertyName))
        isAttribute = strcmp(attributeNames, propertyName);
        isGroup = strcmp(subgroupNames, propertyName);
        isDataset = strcmp(datasetNames, propertyName);
        isLink = strcmp(linkNames, propertyName);
        if any(isAttribute)
            path = {RawClass.attributes(isAttribute)};
        elseif any(isGroup)
            path = {RawClass.subgroups(isGroup)};
        elseif any(isDataset)
            path = {RawClass.datasets(isDataset)};
        elseif any(isLink)
            path = {RawClass.links(isLink)};
        end
        return;
    end

    % find true path for elided property
    if startsWith(propertyName, datasetNames) || startsWith(propertyName, subgroupNames)
        for i=1:length(subgroupNames)
            name = subgroupNames{i};
            suffix = propertyName(length(name)+2:end);
            if startsWith(propertyName, name)
                res = file.internal.traverseRaw(suffix, RawClass.subgroups(i));
                if ~isempty(res)
                    path = [{RawClass.subgroups(i)} res];
                    return;
                end
            end
        end
        for i=1:length(datasetNames)
            name = datasetNames{i};
            suffix = propertyName(length(name)+2:end);
            if startsWith(propertyName, name)
                res = file.internal.traverseRaw(suffix, RawClass.datasets(i));
                if ~isempty(res)
                    path = [{RawClass.datasets(i)} res];
                    return;
                end
            end
        end
    end
end
