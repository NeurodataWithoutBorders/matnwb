function parsed = parseDataset(filename, datasetInfo, datasetPath, exclusions, reader)
% parseDataset - Read an HDF5 dataset and return it as named map entries.
%
% Syntax:
%  parsed = io.parseDataset(filename, datasetInfo, datasetPath, exclusions, reader) 
%  parses the dataset identified by datasetPath in the HDF5 file filename using 
%  metadata from datasetInfo.
%
% Input arguments:
%  - filename  - Path to the HDF5 file.
%  - datasetInfo - Dataset metadata structure, typically obtained from h5info.
%  - datasetPath - Full HDF5 path to the dataset.
%  - exclusions - Attribute and group names to exclude when parsing.
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
%    []. A compound dataset is represented as a DataStub whether or not it
%    holds any rows, so that its member names and types survive the read.

    arguments
        filename (1,:) char
        datasetInfo struct
        datasetPath (1,:) char
        exclusions struct = io.internal.defaultParseExclusions()
        reader io.backend.base.Reader = io.backend.BackendFactory.createReader(filename);
    end

    [parsedAttributes, typeInfo] = ...
        io.parseAttributes(filename, datasetInfo.Attributes, datasetPath, exclusions, reader);

    datasetTypeName = typeInfo.typename;
    isTypedDataset = ~isempty(datasetTypeName);

    datasetValue = reader.readDatasetValue(datasetInfo, datasetPath);

    % Prepare output
    datasetName = datasetInfo.Name;
    parsed = containers.Map;

    if isTypedDataset
        % properties() excludes object_id — a hidden property defined on
        % types.untyped.MetaClass and adopted by its constructor. It must be
        % consumed by the typed dataset itself: left unconsumed, it would be
        % promoted to the parent as '<datasetName>_object_id' (an unknown kwarg
        % that gets dropped) and the child would generate a fresh uuid, breaking
        % object id persistence across read/write round trips.
        consumableNames = [properties(datasetTypeName); {'object_id'}];
        [typeProperties, unconsumedAttributes] = ...
            splitAttributes(parsedAttributes, consumableNames);
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
    promotedAttributes = containers.Map(promotedAttributeNames, attributeValues, 'UniformValues', false);
end
