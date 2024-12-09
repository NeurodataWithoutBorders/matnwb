function JsonData = exportJson()
%TOJSON loads and converts loaded namespaces to json strings
%   returns containers.map of namespace names.

% Get the actual location of the matnwb directory.

namespaceLocation = fileparts(fileparts(fileparts(which('types.core.NWBFile'))));
namespaceList = dir(fullfile(namespaceLocation, 'namespaces'));
isFileMask = ~[namespaceList.isdir];
namespaceFiles = namespaceList(isFileMask);
namespaceNames = {namespaceFiles.name};
for iFile = 1:length(namespaceNames)
    [~, namespaceNames{iFile}, ~] = fileparts(namespaceNames{iFile});
end

Caches = spec.loadCache(namespaceNames{:}, 'savedir', namespaceLocation);
JsonData = struct(...
    'name', namespaceNames,...
    'version', repmat({''}, size(Caches)),...
    'json', repmat({containers.Map.empty}, size(Caches)));
for iCache = 1:length(Caches)
    Cache = Caches(iCache);
    keepRelevantNamespace(Cache);
    removeEmptySchemaComponents(Cache)
    stripNamespaceFileExt(Cache.namespace);
    JsonMap = containers.Map({'namespace'}, {encodeJsonWithConversion(Cache.namespace)});
    for iScheme = 1:length(Cache.filenames)
        filename = Cache.filenames{iScheme};
        jsonencode(Cache.schema(filename));
        JsonMap(filename) = encodeJsonWithConversion(Cache.schema(filename));
    end

    JsonData(iCache).version = Cache.version;
    JsonData(iCache).json = JsonMap;
end
end

function encoded = encodeJsonWithConversion(structs)
if verLessThan('matlab', '9.3')
    % R2017a and older don't support keyword arguments for jsonencode
    warning('NWB:ExportJson:InvalidConversion', ...
        ['MATLAB R2017a and earlier do not support automatic conversion ' ...
        'of NaN, inf, and -inf to json null. If you encounter unreadable ' ...
        'schemas, consider using a newer version of MATLAB.']);
    encoded = jsonencode(structs);
else
    encoded = jsonencode(structs, 'ConvertInfAndNaN', true);
end
end

function removeEmptySchemaComponents(Cache)
Schema = Cache.schema;
SchemaKeys = keys(Schema);
for iScheme = 1:length(SchemaKeys)
    Scheme = Schema(SchemaKeys{iScheme});
    SchemeKeys = keys(Scheme);
    for iSub = 1:length(SchemeKeys)
        SubScheme = Scheme(SchemeKeys{iSub});
        if isempty(SubScheme{1})
            remove(Scheme,SchemeKeys{iSub});
        end
    end
    Schema(SchemaKeys{iScheme}) = Scheme;
end
Cache.schema = Schema;
end

function keepRelevantNamespace(Cache)
Namespaces = Cache.namespace('namespaces');
ns = 1;
while ns <= length(Namespaces)
    Namespace = Namespaces{ns};
    if ~strcmp(Cache.name, Namespace('name'))
        Namespaces(ns) = [];
    end
    ns = ns+1;
end
Cache.namespace('namespaces') = Namespaces;
end

function NamespaceRoot = stripNamespaceFileExt(NamespaceRoot)
Namespaces = NamespaceRoot('namespaces');
for ns = 1:length(Namespaces)
    Namespace = Namespaces{ns};
    Schema = Namespace('schema');
    for iScheme = 1:length(Schema)
        Scheme = Schema{iScheme};
        if ~Scheme.isKey('source')
            continue;
        end
        source = Scheme('source');

        if endsWith(source, '.yaml')
            [~, Scheme('source'), ~] = fileparts(source);
        end
    end
end
end