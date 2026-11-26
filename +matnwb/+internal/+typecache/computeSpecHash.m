function hash = computeSpecHash(namespaceInfo)
% computeSpecHash - Hash the parsed specification of a namespace.
%
%   hash = matnwb.internal.typecache.computeSpecHash(namespaceInfo) returns
%   a SHA-256 hash of the parts of a parsed namespace that class generation
%   reads: its name, version, dependencies and schema. namespaceInfo is one
%   element of the output of spec.generate, or a namespace cache loaded with
%   spec.loadCache.
%
%   The hash is taken over the parsed values, not the source text. A
%   specification therefore hashes the same whether it was read from the
%   YAML files in nwb-schema or from the JSON text embedded in an NWB file.
%   The namespace declaration itself is left out because class generation
%   does not use it, and writers format it differently.

    arguments
        namespaceInfo (1,1) struct
    end

    canonicalText = strjoin([ ...
        "name:" + serializeValue(namespaceInfo.name), ...
        "version:" + serializeValue(namespaceInfo.version), ...
        "dependencies:" + serializeValue(namespaceInfo.dependencies), ...
        "schema:" + serializeValue(namespaceInfo.schema) ...
        ], newline);

    hash = matnwb.internal.typecache.computeSha256(canonicalText);
end

function text = serializeValue(value)
% serializeValue - Serialize a parsed schema value to canonical JSON-like text.
%
%   The keys of a containers.Map are already sorted, so maps serialize in a
%   fixed order regardless of the key order in the source text.

    if isa(value, "containers.Map")
        mapKeys = keys(value);
        entries = cell(1, numel(mapKeys));
        for iKey = 1:numel(mapKeys)
            entries{iKey} = [jsonencode(mapKeys{iKey}), ':', serializeValue(value(mapKeys{iKey}))];
        end
        text = ['{', strjoin(entries, ','), '}'];
    elseif iscell(value)
        entries = cellfun(@serializeValue, reshape(value, 1, []), "UniformOutput", false);
        text = ['[', strjoin(entries, ','), ']'];
    elseif ischar(value) || isstring(value)
        text = jsonencode(char(value));
    elseif islogical(value) && isscalar(value)
        text = char(string(value));
    elseif isnumeric(value) && isscalar(value)
        if isnan(value)
            text = 'null';
        else
            text = sprintf('%.17g', value);
        end
    elseif (isnumeric(value) || islogical(value)) && ~isscalar(value)
        text = serializeValue(num2cell(reshape(value, 1, [])));
    else
        error("NWB:TypeCache:UnsupportedSpecValue", ...
            "Cannot hash a specification value of class ""%s"".", class(value))
    end
end
