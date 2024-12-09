function NamespaceData = getNamespaceInfo(namespaceMap)
errid = 'NWB:Spec:InvalidFile';
errmsg = 'Could not read namespace file.  Invalid format.';

assert(isKey(namespaceMap, 'namespaces'), errid, errmsg);
namespaceMap = namespaceMap('namespaces');

for iInfo = 1:length(namespaceMap)
    NamespaceData(iInfo) = getInfo(namespaceMap{iInfo});
end


    function Info = getInfo(Map)
        requiredKeysExist = isKey(Map, 'name') && isKey(Map, 'schema');
        assert(requiredKeysExist, errid, errmsg);

        name = Map('name');
        if Map.isKey('version')
            version = Map('version');
        else
            version = 'unversioned';
        end
        schema = Map('schema');
        Info = struct(...
            'name', name,...
            'filenames', {cell(size(schema))},...
            'dependencies', {cell(size(schema))},...
            'version', version);
        for iSchemaSource = 1:length(schema)
            schemaReference = schema{iSchemaSource};
            if isKey(schemaReference, 'source')
                sourceReference = schemaReference('source');
                if endsWith(sourceReference, '.yaml')
                    [~, sourceReference, ~] = fileparts(sourceReference);
                end
                Info.filenames{iSchemaSource} = sourceReference;
            elseif isKey(schemaReference, 'namespace')
                Info.dependencies{iSchemaSource} = schemaReference('namespace');
            else
                error(errid, errmsg);
            end
        end
        emptyFileNamesMask = cellfun('isempty', Info.filenames);
        Info.filenames(emptyFileNamesMask) = [];
        emptyDependenciesMask = cellfun('isempty', Info.dependencies);
        Info.dependencies(emptyDependenciesMask) = [];
    end
end