function referenceFields = getObjectReferenceFields(attrs)
% getObjectReferenceFields - Compound fields that hold object references.
%
% Returns the names of a "structured" (compound) array's fields that hold a
% JSON-encoded object reference rather than literal data, read from the
% array's own "zarr_dtype" attribute. For a compound array that attribute is
% a per-field type descriptor list, e.g.
% [{"name":"idx_start","dtype":"int32"}, {"name":"timeseries","dtype":"object"}],
% and a field is a reference when its dtype is "object".
%
% The remaining dtypes restate the field's own Zarr v3 sub-dtype and are
% ignored. The named fields are decoded into types.untyped.ObjectView by
% io.internal.zarr3.decodeObjectReferences.

    referenceFields = string.empty(1, 0);
    if ~isfield(attrs, 'zarr_dtype')
        return
    end

    fieldDescriptors = attrs.zarr_dtype;
    if ~isstruct(fieldDescriptors)
        return
    end

    fieldNames = string({fieldDescriptors.name});
    fieldTypes = string({fieldDescriptors.dtype});
    referenceFields = reshape(fieldNames(fieldTypes == "object"), 1, []);
end
