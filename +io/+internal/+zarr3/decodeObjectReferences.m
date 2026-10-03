function objectViews = decodeObjectReferences(value)
% decodeObjectReferences - Decode hdmf-zarr object references to ObjectViews.
%
% Decodes one or more hdmf-zarr object references into a
% types.untyped.ObjectView array shaped like value. This matches
% io.parseReference's output for HDF5 reference datasets, which
% types.util.checkDtype requires -- a cell array of ObjectView is not an
% accepted dtype.
%
% value may be any on-disk form accepted by hdmf.zarr.Reference.decode: the
% text elements of a reference dataset or of a compound reference field
% (target paths, or JSON records in stores written before hdmf-zarr 0.14);
% an attribute-form reference ({"_REFERENCE": <record>}, or the older
% {"zarr_dtype": "object", "value": <record>}); or a bare reference record.
%
% types.untyped.ObjectView can only address nodes within the file being read,
% so a reference whose source is another store raises
% NWB:Zarr3:UnsupportedExternalReference.
%
% See also:
% hdmf.zarr.Reference, types.untyped.ObjectView

    references = hdmf.zarr.Reference.decode(value);

    isExternal = references.isExternal();
    if any(isExternal)
        firstExternal = references(find(isExternal, 1));
        error("NWB:Zarr3:UnsupportedExternalReference", ...
            "Object references to another store are not supported (source `%s`, path `%s`).", ...
            firstExternal.Source, firstExternal.Path)
    end

    objectViews = types.untyped.ObjectView.empty(0, 0);
    for iReference = 1:numel(references)
        objectViews(iReference) = types.untyped.ObjectView(char(references(iReference).Path));
    end
    objectViews = reshape(objectViews, size(references));
end
