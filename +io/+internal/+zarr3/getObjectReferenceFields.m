function referenceFields = getObjectReferenceFields(attrs)
% getObjectReferenceFields - Compound fields that hold object references.
%
% Returns the names of a structured (compound) array's fields that hold an
% object reference rather than literal data, read from the array's
% attributes (its attrs dictionary). hdmf-zarr lists those fields in the
% "_REFERENCE_FIELDS" attribute, e.g. ["timeseries"]; a compound dataset
% without reference fields carries no such attribute.
%
% The named fields are decoded into types.untyped.ObjectView by
% io.internal.zarr3.decodeObjectReferences.

    referenceFields = string.empty(1, 0);

    [hasReferenceFields, fieldNames] = io.internal.zarr3.getAttribute(attrs, "_REFERENCE_FIELDS");
    if hasReferenceFields && ~isempty(fieldNames)
        referenceFields = reshape(string(fieldNames), 1, []);
    end
end
