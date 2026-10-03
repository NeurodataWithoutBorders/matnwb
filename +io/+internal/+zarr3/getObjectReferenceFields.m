function referenceFields = getObjectReferenceFields(attrs)
% getObjectReferenceFields - Compound fields that hold object references.
%
% Returns the names of a structured (compound) array's fields that hold an
% object reference rather than literal data, read from the array's
% attributes (its attrs dictionary). hdmf-zarr lists those fields in the
% "_REFERENCE_FIELDS" attribute, e.g. ["timeseries"]. Stores written before
% hdmf-zarr 0.14 instead carry a per-field type descriptor list in
% "zarr_dtype", e.g.
% [{"name":"idx_start","dtype":"int32"}, {"name":"timeseries","dtype":"object"}],
% where a field is a reference when its dtype is "object". As in hdmf-zarr,
% "_REFERENCE_FIELDS" is read in preference to "zarr_dtype".
%
% The named fields are decoded into types.untyped.ObjectView by
% io.internal.zarr3.decodeObjectReferences.

    referenceFields = string.empty(1, 0);

    [hasReferenceFields, fieldNames] = io.internal.zarr3.getAttribute(attrs, "_REFERENCE_FIELDS");
    if hasReferenceFields
        if ~isempty(fieldNames)
            referenceFields = reshape(string(fieldNames), 1, []);
        end
        return
    end

    [hasLegacyDtype, fieldDescriptors] = io.internal.zarr3.getAttribute(attrs, "zarr_dtype");
    % For a non-compound dataset zarr_dtype is a scalar string (e.g.
    % "object"), not a descriptor list; such a dataset has no fields.
    if ~hasLegacyDtype || ~iscell(fieldDescriptors)
        return
    end

    isReference = false(1, numel(fieldDescriptors));
    names = strings(1, numel(fieldDescriptors));
    for iField = 1:numel(fieldDescriptors)
        [~, name] = io.internal.zarr3.getAttribute(fieldDescriptors{iField}, "name");
        [~, dtype] = io.internal.zarr3.getAttribute(fieldDescriptors{iField}, "dtype");
        names(iField) = string(name);
        isReference(iField) = isequal(string(dtype), "object");
    end
    referenceFields = names(isReference);
end
