function specs = readEmbeddedSpecifications(filename, specLocation)
% readEmbeddedSpecifications - Read embedded specs from an NWB file
%
%   specs = io.spec.readEmbeddedSpecifications(filename, specLocation) read 
%       embedded specs from the specLocation in an NWB file
%
%   Inputs:
%       filename (string) : Absolute path of an nwb file
%       specLocation (string) : h5 path for the location of specs inside the NWB file
%
%   Outputs
%       specs cell: A cell array of structs with one element for each embedded
%           specification. Each struct has two fields:
%
%       - namespaceName (char)      : Name of the namespace for a specification
%       - namespaceText (char)      : The namespace declaration for a specification
%       - schemaMap (containers.Map): A set of schema specifications for the namespace

    arguments
        filename (1,1) string {matnwb.common.mustBeNwbFile}
        specLocation (1,1) string
    end

    specInfo = h5info(filename, specLocation);
    specs = deal( cell(size(specInfo.Groups)) );
    
    fid = H5F.open(filename);
    fileCleanup = onCleanup(@(id) H5F.close(fid) );

    for iGroup = 1:length(specInfo.Groups)
        location = specInfo.Groups(iGroup).Groups(1);

        namespaceName = split(specInfo.Groups(iGroup).Name, '/');
        namespaceName = namespaceName{end};

        filenames = {location.Datasets.Name};
        if ~any(strcmp('namespace', filenames))
            warning('NWB:Read:GenerateSpec:CacheInvalid',...
                'Couldn''t find a `namespace` in namespace `%s`.  Skipping cache generation.',...
                namespaceName);
            return;
        end
        sourceNames = {location.Datasets.Name};
        fileLocation = strcat(location.Name, '/', sourceNames);
        schemaMap = containers.Map;
        for iFileLocation = 1:length(fileLocation)
            did = H5D.open(fid, fileLocation{iFileLocation});
            if strcmp('namespace', sourceNames{iFileLocation})
                namespaceText = H5D.read(did);
            else
                schemaMap(sourceNames{iFileLocation}) = H5D.read(did);
            end
            H5D.close(did);
        end

        specs{iGroup}.namespaceName = namespaceName;
        specs{iGroup}.namespaceText = namespaceText;
        specs{iGroup}.schemaMap = schemaMap;
    end
end
