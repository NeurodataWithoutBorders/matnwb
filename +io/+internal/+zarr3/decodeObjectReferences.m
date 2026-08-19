function objectViews = decodeObjectReferences(value)
% decodeObjectReferences - Decode hdmf-zarr object references into ObjectViews.
%
%   objectViews = decodeObjectReferences(value) decodes one or more hdmf-zarr
%   object references into a types.untyped.ObjectView array shaped like
%   value (matching io.parseReference's output for HDF5 reference datasets,
%   which types.util.checkDtype requires -- a cell array of ObjectView is
%   not an accepted dtype).
%
%   value may be any on-disk form accepted by hdmf.zarr.Reference.decode:
%     - JSON string(s): the elements of a zarr_dtype:"object" dataset or
%       of an "object"-tagged compound field
%     - the attribute form struct {zarr_dtype:"object", value:<record>}
%     - a bare reference record struct
%
%   types.untyped.ObjectView can only address nodes within the file being
%   read, so a reference whose source is another store raises
%   NWB:Zarr3:UnsupportedExternalReference.
%
%   See also hdmf.zarr.Reference, types.untyped.ObjectView

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
