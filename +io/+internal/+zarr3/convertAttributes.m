function [attributes, links] = convertAttributes(rawAttributes)
% convertAttributes - Convert zarr-matlab attrs into h5info-like structures.
%
% [attributes, links] = convertAttributes(rawAttributes) converts the
% attrs struct exposed by a zarr.Group or zarr.Array (as returned by
% zarr-matlab) into:
%
%     attributes - struct array with fields Name, Datatype, Dataspace,
%       Value, matching the shape produced by h5info. An attribute holding
%       an hdmf-zarr object reference (the {zarr_dtype:"object", value:...}
%       form; see hdmf.zarr.Reference) is tagged with Datatype
%       "object reference" and keeps the raw record as its Value, which
%       io.backend.zarr3.Zarr3Reader.readAttributeValue decodes.
%
%     links - struct array with fields Name, Type, Value, converted from the
%       hdmf-zarr "zarr_link" attribute (decoded by hdmf.zarr.Link).
%       Non-group nodes never carry links, but the reserved attribute is
%       filtered out regardless.
%
% The hdmf-zarr bookkeeping attributes (zarr_link, zarr_dtype, .specloc,
% _ARRAY_DIMENSIONS) are not schema attributes and are never promoted to
% the attributes output.
%
% This convention matches the shape produced by h5info, so that the same
% downstream parsing code (io.parseGroup, io.parseAttributes) can consume
% node info from any backend.
%
% See also hdmf.zarr.Link, hdmf.zarr.Reference

    attributes = emptyAttributeStruct();
    links = emptyLinkStruct();

    if isempty(rawAttributes) || ~isstruct(rawAttributes)
        return
    end

    links = convertLinks(hdmf.zarr.Link.fromAttributes(rawAttributes));

    fieldNames = fieldnames(rawAttributes);
    for iField = 1:numel(fieldNames)
        name = fieldNames{iField};
        value = rawAttributes.(name);

        if isReservedAttribute(name)
            continue
        end

        if iscell(value) && ~isscalar(value)
            % struct(...,'Value',value) would otherwise expand a non-scalar
            % cell into a non-scalar struct array (one element per cell
            % entry) instead of a single attribute whose Value is the cell.
            value = {value};
        end

        attribute = struct('Name', name, 'Datatype', [], 'Dataspace', [], 'Value', value);
        if isObjectReferenceValue(value)
            attribute.Datatype = 'object reference';
        end
        attributes(end+1) = attribute; %#ok<AGROW>
    end
end

function tf = isReservedAttribute(name)
% isReservedAttribute - True for hdmf-zarr bookkeeping attributes.
%
% Names are as they appear after jsondecode, which renames keys that are not
% valid MATLAB identifiers: ".specloc" (the root attribute naming the cached
% specifications group, read by io.backend.zarr3.Zarr3Reader) becomes
% "x_specloc", and "_ARRAY_DIMENSIONS" (xarray dimension names) becomes
% "x_ARRAY_DIMENSIONS".

    reservedNames = ["zarr_link", "zarr_dtype", ...
        io.internal.zarr3.getSpecLocAttributeName(), ...
        matlab.lang.makeValidName("_ARRAY_DIMENSIONS")];
    tf = any(strcmp(name, reservedNames));
end

function tf = isObjectReferenceValue(value)
% isObjectReferenceValue - True for the attribute form of a reference.
%
% The attribute form of an hdmf-zarr object reference is
% {zarr_dtype:"object", value:<record>}, the shape
% hdmf.zarr.Reference.encodeAttribute produces.

    tf = isstruct(value) && isscalar(value) ...
        && isfield(value, 'zarr_dtype') ...
        && strcmp(string(value.zarr_dtype), "object");
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
