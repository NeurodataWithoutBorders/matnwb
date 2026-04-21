function writeEmbeddedSpecifications(writer, jsonSpecs)
% writeEmbeddedSpecifications - Write schema specifications to an NWB file

    arguments
        writer (1,1) io.backend.base.Writer
        jsonSpecs   % String representation of schema specifications in json format
    end

    specLocation = io.spec.internal.readEmbeddedSpecLocation(writer.FileId);

    if isempty(specLocation)
        specLocation = '/specifications';
        writer.writeGroup(specLocation);
        specView = types.untyped.ObjectView(specLocation);
        writer.writeAttribute('/.specloc', specView);
    end

    for iJson = 1:length(jsonSpecs)
        JsonDatum = jsonSpecs(iJson);
        schemaNamespaceLocation = strjoin({specLocation, JsonDatum.name}, '/');
        namespaceExists = writer.writeGroup(schemaNamespaceLocation);
        if namespaceExists
            namespaceGroupId = H5G.open(writer.FileId, schemaNamespaceLocation);
            names = getVersionNames(namespaceGroupId);
            H5G.close(namespaceGroupId);
            for iNames = 1:length(names)
                H5L.delete(writer.FileId, [schemaNamespaceLocation '/' names{iNames}],...
                    'H5P_DEFAULT');
            end
        end
        schemaLocation = ...
            strjoin({schemaNamespaceLocation, JsonDatum.version}, '/');
        writer.writeGroup(schemaLocation);
        Json = JsonDatum.json;
        schemeNames = keys(Json);
        for iScheme = 1:length(schemeNames)
            name = schemeNames{iScheme};
            path = [schemaLocation '/' name];
            writer.writeValue(path, Json(name));
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
