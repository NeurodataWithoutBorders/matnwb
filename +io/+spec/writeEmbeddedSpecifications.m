function writeEmbeddedSpecifications(fid, jsonSpecs)
% writeEmbeddedSpecifications - Write schema specifications to an NWB file

    arguments
        fid         % File id for a h5 file
        jsonSpecs   % String representation of schema specifications in json format
    end

    specLocation = io.spec.internal.readEmbeddedSpecLocation(fid);

    if isempty(specLocation)
        specLocation = '/specifications';
        io.writeGroup(fid, specLocation);
        specView = types.untyped.ObjectView(specLocation);
        io.writeAttribute(fid, '/.specloc', specView);
    end

    for iJson = 1:length(jsonSpecs)
        JsonDatum = jsonSpecs(iJson);
        schemaNamespaceLocation = strjoin({specLocation, JsonDatum.name}, '/');
        namespaceExists = io.writeGroup(fid, schemaNamespaceLocation);
        if namespaceExists
            namespaceGroupId = H5G.open(fid, schemaNamespaceLocation);
            names = getVersionNames(namespaceGroupId);
            H5G.close(namespaceGroupId);
            for iNames = 1:length(names)
                H5L.delete(fid, [schemaNamespaceLocation '/' names{iNames}],...
                    'H5P_DEFAULT');
            end
        end
        schemaLocation =...
            strjoin({schemaNamespaceLocation, JsonDatum.version}, '/');
        io.writeGroup(fid, schemaLocation);
        Json = JsonDatum.json;
        schemeNames = keys(Json);
        for iScheme = 1:length(schemeNames)
            name = schemeNames{iScheme};
            path = [schemaLocation '/' name];
            io.writeDataset(fid, path, Json(name));
        end
    end
end

function versionNames = getVersionNames(namespaceGroupId)
    [~, ~, versionNames] = H5L.iterate(namespaceGroupId,...
        'H5_INDEX_NAME', 'H5_ITER_NATIVE',...
        0, @appendName, {});
    function [status, versionNames] = appendName(~, name, versionNames)
        versionNames{end+1} = name;
        status = 0;
    end
end
