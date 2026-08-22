function fieldSemantics = getCompoundFieldSemantics(attrs)
% getCompoundFieldSemantics - Per-field type hints of a compound array.
%
% Returns a containers.Map from field name (char) to semantic dtype (string),
% read from a "structured" (compound) array's own "zarr_dtype" attribute. For
% a compound array that attribute is a per-field type descriptor list, e.g.
% [{"name":"idx_start","dtype":"int32"}, {"name":"timeseries","dtype":"object"}].
%
% The only semantic value consumed downstream is "object": the field holds a
% JSON-encoded object reference rather than literal text/data, decoded by
% io.internal.zarr3.decodeObjectReferences. Other hints are redundant with the
% field's own Zarr v3 sub-dtype and are ignored.

    fieldSemantics = containers.Map('KeyType', 'char', 'ValueType', 'any');
    if ~isfield(attrs, 'zarr_dtype')
        return
    end

    fieldDescriptors = attrs.zarr_dtype;
    if ~isstruct(fieldDescriptors)
        return
    end

    for iField = 1:numel(fieldDescriptors)
        fieldSemantics(char(fieldDescriptors(iField).name)) = ...
            string(fieldDescriptors(iField).dtype);
    end
end
