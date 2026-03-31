function parsed = parseDataset(filename, datasetInfo, datasetPath, blacklist, reader)
% parseDataset - Read an HDF5 dataset and return it as named map entries.
%
% Syntax:
%  parsed = io.parseDataset(filename, datasetInfo, datasetPath, blacklist, reader) 
%  parses the dataset identified by datasetPath in the HDF5 file filename using 
%  metadata from datasetInfo.
%
% Input arguments:
%  - filename  - Path to the HDF5 file.
%  - datasetInfo - Dataset metadata structure, typically obtained from h5info.
%  - datasetPath - Full HDF5 path to the dataset.
%  - blacklist - Attribute names or rules to exclude when parsing attributes.
%  - reader - An object of an NWB reader class (io.backend.base.Reader)
%
% Output argument:
%  - parsed - containers.Map with the following entries:
%
%      parsed('datasetName')
%          The parsed dataset value (untyped) or typed object (typed).
%
%      parsed('datasetName_attrName')
%          Dataset attributes not consumed during typed object creation,
%          or all attributes for untyped datasets.
%
% Notes:
%  - The primary map key is the dataset leaf name from datasetInfo.Name, not
%    datasetPath.
%  - For typed datasets, attributes are considered consumable if their
%    names match public properties of the neurodata type class. Consumed
%    attributes are used to construct the typed object and are not
%    promoted into the output map.
%  - HDF5 reference datasets are fully read and resolved.
%  - Scalar datasets are read eagerly and postprocessed according to their
%    datatype.
%  - For non-scalar datasets, chunked numeric datasets are represented as
%    DataPipe, other non-empty datasets as DataStub, and empty datasets as
%    [].

    arguments
        filename (1,:) char
        datasetInfo struct
        datasetPath (1,:) char
        blacklist struct = struct('attributes', {{}}, 'groups', {{}})
        reader io.backend.base.Reader = io.backend.BackendFactory.createReader(filename);
    end

    [parsedAttributes, typeInfo] = ...
        io.parseAttributes(filename, datasetInfo.Attributes, datasetPath, blacklist, reader);

    datasetTypeName = typeInfo.typename;
    isTypedDataset = ~isempty(datasetTypeName);

    datasetValue = reader.readDatasetValue(datasetInfo, datasetPath);

    % Prepare output
    datasetName = datasetInfo.Name;
    parsed = containers.Map;

    if isTypedDataset
        [typeProperties, unconsumedAttributes] = ...
            splitAttributes(parsedAttributes, properties(datasetTypeName));
        typeProperties('data') = datasetValue;
        kwargs = io.map2kwargs(typeProperties);
        parsed(datasetName) = io.createParsedType(datasetPath, datasetTypeName, kwargs{:});
        parsed = [parsed; promoteDatasetAttributes(datasetName, unconsumedAttributes)];
    else
        parsed(datasetName) = datasetValue;
        parsed = [parsed; promoteDatasetAttributes(datasetName, parsedAttributes)];
    end
end

function [consumable, nonConsumable] = splitAttributes(attributes, consumableNames)
    attributeNames = keys(attributes);
    isConsumable = ismember(attributeNames, consumableNames);
    
    consumable = buildSubmap(attributes, attributeNames(isConsumable));
    nonConsumable = buildSubmap(attributes, attributeNames(~isConsumable));
    
    function submap = buildSubmap(sourceMap, selectedKeys)
        if isempty(selectedKeys)
            submap = containers.Map();
        else
            submap = containers.Map(selectedKeys, values(sourceMap, selectedKeys), 'UniformValues', false);
        end
    end
end

function promotedAttributes = promoteDatasetAttributes(datasetName, attributes)
    promotedAttributes = containers.Map;

    attributeNames = keys(attributes);
    if isempty(attributeNames)
        return;
    end

    promotedAttributeNames = strcat(datasetName, '_', attributeNames);
    attributeValues = values(attributes, attributeNames);
    promotedAttributes = containers.Map(promotedAttributeNames, attributeValues);
end
