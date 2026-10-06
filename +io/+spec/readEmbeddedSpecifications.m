function specs = readEmbeddedSpecifications(reader, specLocation)
% readEmbeddedSpecifications - Read embedded specs from an NWB file
%
%   specs = io.spec.readEmbeddedSpecifications(reader, specLocation) reads
%       embedded specs from the specLocation in an NWB file, using reader
%       (an io.backend.base.Reader) to access the file. Backend-agnostic:
%       only uses the io.backend.base.Reader interface, so this works for
%       any registered storage backend, not just HDF5.
%
%   Inputs:
%       reader (io.backend.base.Reader) : Reader for the NWB file
%       specLocation (string) : Path for the location of specs inside the NWB file
%
%   Outputs
%       specs cell: A cell array of structs with one element for each embedded
%           specification. Each struct has two fields:
%
%       - namespaceName (char)      : Name of the namespace for a specification
%       - namespaceText (char)      : The namespace declaration for a specification
%       - schemaMap (containers.Map): A set of schema specifications for the namespace

    arguments
        reader (1,1) io.backend.base.Reader
        specLocation (1,1) string
    end

    specInfo = reader.readNodeInfo(specLocation);
    specs = deal( cell(size(specInfo.Groups)) );

    for iGroup = 1:length(specInfo.Groups)
        namespaceGroupInfo = specInfo.Groups(iGroup);
        location = namespaceGroupInfo.Groups(1);

        namespaceName = split(namespaceGroupInfo.Name, '/');
        namespaceName = namespaceName{end};

        datasetNames = {location.Datasets.Name};
        if ~any(strcmp('namespace', datasetNames))
            warning('NWB:Read:GenerateSpec:CacheInvalid',...
                'Couldn''t find a `namespace` in namespace `%s`.  Skipping cache generation.',...
                namespaceName);
            return;
        end

        schemaMap = containers.Map;
        for iDataset = 1:length(datasetNames)
            datasetName = datasetNames{iDataset};
            datasetPath = strcat(location.Name, '/', datasetName);
            datasetValue = reader.readDatasetValue(location.Datasets(iDataset), datasetPath);
            if strcmp('namespace', datasetName)
                namespaceText = datasetValue;
            else
                schemaMap(datasetName) = datasetValue;
            end
        end

        specs{iGroup}.namespaceName = namespaceName;
        specs{iGroup}.namespaceText = namespaceText;
        specs{iGroup}.schemaMap = schemaMap;
    end
end
