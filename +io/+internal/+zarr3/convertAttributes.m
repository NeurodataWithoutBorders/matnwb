function [attributes, links] = convertAttributes(rawAttributes)
% convertAttributes - Convert zarr-matlab attrs into h5info-like structures.
%
%   [attributes, links] = convertAttributes(rawAttributes) converts the
%   attrs struct exposed by a zarr.Group or zarr.Array (as returned by
%   zarr-matlab) into:
%
%     attributes - struct array with fields Name, Datatype, Dataspace,
%       Value, matching the shape produced by h5info. Object references
%       (see io.internal.zarr3.encodeObjectReference) are tagged with
%       Datatype "object reference".
%
%     links - struct array with fields Name, Type, Value, decoded from the
%       reserved "zarr_link" attribute (soft/external link records written
%       by io.backend.zarr3.Zarr3Writer). Non-group nodes never carry links,
%       but the reserved attribute is filtered out regardless.
%
%   This convention matches the shape produced by h5info, so that the same
%   downstream parsing code (io.parseGroup, io.parseAttributes) can consume
%   node info from any backend.

    attributes = emptyAttributeStruct();
    links = emptyLinkStruct();

    if isempty(rawAttributes) || ~isstruct(rawAttributes)
        return
    end

    fieldNames = fieldnames(rawAttributes);
    for iField = 1:numel(fieldNames)
        name = fieldNames{iField};
        value = rawAttributes.(name);

        if strcmp(name, "zarr_link")
            links = convertLinks(value);
            continue
        elseif strcmp(name, "x_specloc")
            % Reserved marker for io.backend.zarr3.Zarr3Reader.getEmbeddedSpecLocation;
            % not a schema attribute, so it is never promoted.
            continue
        elseif strcmp(name, "zarr_dtype") || strcmp(name, "x_ARRAY_DIMENSIONS")
            % Reserved bookkeeping attributes written by hdmf-zarr-style
            % exporters (dtype hint / xarray dimension names, the latter
            % written to disk as "_ARRAY_DIMENSIONS" but renamed by
            % jsondecode since a leading underscore is not a valid MATLAB
            % identifier); not schema attributes.
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

function tf = isObjectReferenceValue(value)
    tf = isstruct(value) && isscalar(value) ...
        && isfield(value, 'zarr_dtype') ...
        && strcmp(string(value.zarr_dtype), "object");
end

function links = convertLinks(rawLinks)
    links = emptyLinkStruct();
    if isempty(rawLinks)
        return
    end
    if ~iscell(rawLinks)
        rawLinks = num2cell(rawLinks);
    end

    for iLink = 1:numel(rawLinks)
        rawLink = rawLinks{iLink};
        link = struct('Name', char(rawLink.name), 'Type', '', 'Value', []);
        if strcmp(rawLink.source, '.')
            link.Type = 'soft link';
            link.Value = {char(rawLink.path)};
        else
            link.Type = 'external link';
            link.Value = {char(rawLink.source), char(rawLink.path)};
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
