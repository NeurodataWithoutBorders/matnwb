function [attributes, links] = convertAttributes(rawAttributes)
% convertAttributes - Describe the attributes and links of a zarr-matlab node.
%
% [attributes, links] = convertAttributes(rawAttributes) converts the
% attributes dictionary exposed by a zarr.Group or zarr.Array (its attrs
% property) into:
%
%     attributes - io.backend.model.AttributeInfo array. The BackendInfo of
%       each is a struct with the field IsReference. An attribute holding
%       an hdmf-zarr object reference, the {"_REFERENCE": <record>} form
%       (see hdmf.zarr.Reference), has IsReference true and keeps the raw
%       record as its Value, which
%       io.backend.zarr3.Zarr3Reader.readAttributeValue decodes.
%
%     links - io.backend.model.LinkInfo array, converted from the
%       hdmf-zarr "_LINKS" attribute (decoded by hdmf.zarr.Link). Non-group
%       nodes never carry links, but the reserved attributes are filtered
%       out regardless.
%
% The hdmf-zarr bookkeeping attributes (_LINKS, _DTYPE, _REFERENCE_FIELDS,
% .specloc, and _ARRAY_DIMENSIONS) are not schema attributes and are never
% promoted to the attributes output.
%
% Attribute values are returned in the form the parse functions read for
% every backend (io.parseGroup, io.parseAttributes, io.getNeurodataTypeInfo):
% text as char, a list of text as a cellstr, and a list of numbers or
% logicals as a column vector. zarr-matlab instead decodes every JSON
% string to a string scalar and every JSON array to a cell.
%
% See also hdmf.zarr.Link, hdmf.zarr.Reference

    attributes = io.backend.model.AttributeInfo.empty(0, 1);
    links = io.backend.model.LinkInfo.empty(0, 1);

    if ~isa(rawAttributes, "dictionary") || numEntries(rawAttributes) == 0
        return
    end

    links = convertLinks(hdmf.zarr.Link.fromAttributes(rawAttributes));

    attributeNames = keys(rawAttributes);
    for iAttribute = 1:numel(attributeNames)
        name = attributeNames(iAttribute);
        if isReservedAttribute(name)
            continue
        end

        value = rawAttributes{name};
        isReference = isObjectReferenceValue(value);
        if ~isReference
            value = normalizeValue(value);
        end

        attributes(end+1, 1) = io.backend.model.AttributeInfo(name, value, ...
            struct('IsReference', isReference)); %#ok<AGROW>
    end
end

function tf = isReservedAttribute(name)
% isReservedAttribute - True for hdmf-zarr bookkeeping attributes.
%
% "_ARRAY_DIMENSIONS" holds xarray dimension names; ".specloc" names the
% cached specifications group and is read by io.backend.zarr3.Zarr3Reader.

    reservedNames = ["_LINKS", "_DTYPE", "_REFERENCE_FIELDS", ...
        io.backend.zarr3.internal.getSpecLocAttributeName(), "_ARRAY_DIMENSIONS"];
    tf = any(name == reservedNames);
end

function tf = isObjectReferenceValue(value)
% isObjectReferenceValue - True for the attribute form of a reference.
%
% hdmf-zarr wraps a reference stored in an attribute as
% {"_REFERENCE": <record>}.

    tf = io.backend.zarr3.internal.getAttribute(value, "_REFERENCE");
end

function value = normalizeValue(value)
% normalizeValue - Convert a zarr-matlab attribute value to its MATLAB form.
%
% A cell whose elements are all text becomes a cellstr, and one whose
% elements are all numeric (or all logical) scalars becomes a column vector.
% A list of equally long numeric lists becomes a matrix with one row per
% inner list, as jsondecode reads it. Anything else -- a mixed list, a
% nested object -- is returned unchanged.

    if isstring(value) && isscalar(value)
        value = char(value);
        return
    end
    if ~iscell(value)
        return
    end
    if isempty(value)
        value = [];
        return
    end

    elements = cellfun(@normalizeValue, value, "UniformOutput", false);
    if all(cellfun(@ischar, elements))
        value = elements;
    elseif all(cellfun(@isNumericScalar, elements)) || all(cellfun(@isLogicalScalar, elements))
        value = vertcat(elements{:});
    elseif all(cellfun(@isNumericColumn, elements)) ...
            && isscalar(unique(cellfun(@numel, elements)))
        rows = cellfun(@transpose, elements, "UniformOutput", false);
        value = vertcat(rows{:});
    end
end

function tf = isNumericScalar(value)
    tf = isnumeric(value) && isscalar(value);
end

function tf = isLogicalScalar(value)
    tf = islogical(value) && isscalar(value);
end

function tf = isNumericColumn(value)
    tf = isnumeric(value) && iscolumn(value);
end

function links = convertLinks(hdmfLinks)
% convertLinks - Describe hdmf.zarr.Link objects as io.backend.model.LinkInfo.

    links = io.backend.model.LinkInfo.empty(0, 1);
    for iLink = numel(hdmfLinks):-1:1
        name = hdmfLinks(iLink).Name;
        target = hdmfLinks(iLink).Target;
        if target.isExternal()
            links(iLink, 1) = io.backend.model.LinkInfo(name, 'external link', ...
                target.Path, target.Source);
        else
            links(iLink, 1) = io.backend.model.LinkInfo(name, 'soft link', target.Path);
        end
    end
end
