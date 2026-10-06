function [attributes, links] = convertAttributes(rawAttributes)
% convertAttributes - Convert zarr-matlab attrs into h5info-like structures.
%
% [attributes, links] = convertAttributes(rawAttributes) converts the
% attributes dictionary exposed by a zarr.Group or zarr.Array (its attrs
% property) into:
%
%     attributes - struct array with fields Name, Datatype, Dataspace,
%       Value, matching the shape produced by h5info. An attribute holding
%       an hdmf-zarr object reference, the {"_REFERENCE": <record>} form
%       (see hdmf.zarr.Reference), is tagged with Datatype "object
%       reference" and keeps the raw record as its Value, which
%       io.backend.zarr3.Zarr3Reader.readAttributeValue decodes.
%
%     links - struct array with fields Name, Type, Value, converted from the
%       hdmf-zarr "_LINKS" attribute (decoded by hdmf.zarr.Link). Non-group
%       nodes never carry links, but the reserved attributes are filtered
%       out regardless.
%
% The hdmf-zarr bookkeeping attributes (_LINKS, _DTYPE, _REFERENCE_FIELDS,
% .specloc, and _ARRAY_DIMENSIONS) are not schema attributes and are never
% promoted to the attributes output.
%
% Attribute values are returned in the form h5info gives for the same data,
% so that the same downstream parsing code (io.parseGroup,
% io.parseAttributes) can consume node info from any backend: text as char,
% a list of text as a cellstr, and a list of numbers or logicals as a column
% vector. zarr-matlab instead decodes every JSON string to a string scalar
% and every JSON array to a cell.
%
% See also hdmf.zarr.Link, hdmf.zarr.Reference

    attributes = emptyAttributeStruct();
    links = emptyLinkStruct();

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
        if isObjectReferenceValue(value)
            datatype = 'object reference';
        else
            datatype = [];
            value = normalizeValue(value);
        end

        if iscell(value)
            % struct(...,'Value',value) would otherwise expand a cell into a
            % struct array (one element per cell entry) instead of a single
            % attribute whose Value is the cell.
            value = {value};
        end

        attributes(end+1) = struct('Name', char(name), 'Datatype', datatype, ...
            'Dataspace', [], 'Value', value); %#ok<AGROW>
    end
end

function tf = isReservedAttribute(name)
% isReservedAttribute - True for hdmf-zarr bookkeeping attributes.
%
% "_ARRAY_DIMENSIONS" holds xarray dimension names; ".specloc" names the
% cached specifications group and is read by io.backend.zarr3.Zarr3Reader.

    reservedNames = ["_LINKS", "_DTYPE", "_REFERENCE_FIELDS", ...
        io.internal.zarr3.getSpecLocAttributeName(), "_ARRAY_DIMENSIONS"];
    tf = any(name == reservedNames);
end

function tf = isObjectReferenceValue(value)
% isObjectReferenceValue - True for the attribute form of a reference.
%
% hdmf-zarr wraps a reference stored in an attribute as
% {"_REFERENCE": <record>}.

    tf = io.internal.zarr3.getAttribute(value, "_REFERENCE");
end

function value = normalizeValue(value)
% normalizeValue - Convert a zarr-matlab attribute value to its h5info form.
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
% convertLinks - Map hdmf.zarr.Link objects onto h5info's Links struct.
%
% Produces the shape (Name, Type, Value) io.parseGroup expects: a soft link's
% Value is {path}; an external link's Value is {source, path}.

    links = emptyLinkStruct();
    for iLink = 1:numel(hdmfLinks)
        target = hdmfLinks(iLink).Target;
        link = struct('Name', char(hdmfLinks(iLink).Name), 'Type', '', 'Value', []);
        if target.isExternal()
            link.Type = 'external link';
            link.Value = {char(target.Source), char(target.Path)};
        else
            link.Type = 'soft link';
            link.Value = {char(target.Path)};
        end
        links(end+1) = link; %#ok<AGROW>
    end
end

function attributeStruct = emptyAttributeStruct()
    attributeStruct = struct('Name', {}, 'Datatype', {}, 'Dataspace', {}, 'Value', {});
end

function linkStruct = emptyLinkStruct()
    linkStruct = struct('Name', {}, 'Type', {}, 'Value', {});
end
