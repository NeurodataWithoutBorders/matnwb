%returns sources given namespace java object
function s = getNamespaceInfo(namespaceMap)
errid = 'MATNWB:INVALIDFILE';
errmsg = 'Could not read namespace file.  Invalid format.';

assert(namespaceMap.containsKey('namespaces'), errid, errmsg);
namespaceIter = namespaceMap.get('namespaces').iterator();

%spawn empty struct.  Produce struct array of all defined namespaces
s = struct('filenames', {}, 'name', {}, 'dependencies', {}, 'version', {});
sidx = 1;
while namespaceIter.hasNext()
    namespace = namespaceIter.next();
    assert(namespace.containsKey('name')...
        && namespace.containsKey('schema')...
        && namespace.containsKey('version'),...
        errid, errmsg);
    name = namespace.get('name');
    version = namespace.get('version');
    filenames = {};
    dependencies = {};
    schemaIter = namespace.get('schema').iterator();
    while schemaIter.hasNext()
        schemaFile = schemaIter.next();
        if schemaFile.containsKey('source')
            filenames{end+1} = schemaFile.get('source');
        elseif schemaFile.containsKey('namespace')
            dependencies{end+1} = schemaFile.get('namespace');
        else
            error(errid, errmsg);
        end
    end
    
    name = misc.str2validName(name);
    s(sidx) = struct('name', name,...
        'filenames', {filenames},...
        'dependencies', {dependencies},...
        'version', version);
end
end