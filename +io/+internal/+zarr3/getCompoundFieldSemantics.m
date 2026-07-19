function fieldSemantics = getCompoundFieldSemantics(attrs)
% getCompoundFieldSemantics - Per-field semantic type hints for a
% "structured" (compound) Zarr v3 array.
%
%   fieldSemantics = getCompoundFieldSemantics(attrs) returns a
%   containers.Map from field name (char) to semantic dtype (string),
%   read from the array's own "zarr_dtype" attribute -- for a compound
%   array this is a per-field type descriptor list (matching the
%   hdmf-zarr v2 convention), e.g.
%   [{"name":"idx_start","dtype":"int32"}, ...,
%    {"name":"timeseries","dtype":"object"}].
%
%   The only semantic value consumed downstream is "object" (the field
%   holds a JSON-encoded object reference rather than literal text/data),
%   matching io.backend.zarr3.Zarr3Reader.readObjectArrayValue's
%   convention for top-level arrays of references. Other hints are
%   redundant with the field's own Zarr v3 sub-dtype and are ignored.

    fieldSemantics = containers.Map('KeyType', 'char', 'ValueType', 'any');
    if ~isfield(attrs, 'zarr_dtype')
        return
    end

    fieldDescriptors = attrs.zarr_dtype;
    if ~isstruct(fieldDescriptors)
        return
    end

    for i = 1:numel(fieldDescriptors)
        fieldSemantics(char(fieldDescriptors(i).name)) = string(fieldDescriptors(i).dtype);
    end
end
