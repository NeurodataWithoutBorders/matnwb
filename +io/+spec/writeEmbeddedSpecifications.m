function writeEmbeddedSpecifications(writer, jsonSpecs)
% writeEmbeddedSpecifications - Write schema specifications to an NWB file
%
%   Backend-agnostic: only uses the io.backend.base.Writer interface, so
%   this works for any registered storage backend, not just HDF5.

    arguments
        writer (1,1) io.backend.base.Writer
        jsonSpecs   % String representation of schema specifications in json format
    end

    specLocation = writer.getEmbeddedSpecLocation();

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
            names = writer.listChildGroupNames(schemaNamespaceLocation);
            for iNames = 1:length(names)
                writer.deleteGroup([schemaNamespaceLocation '/' names{iNames}]);
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
