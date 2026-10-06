function [args, type] = parseAttributes(filename, attributes, context, exclusions, reader)
% parseAttributes - Parse an attribute info structure
%
% Syntax:
%   [args, type] = io.parseAttributes(filename, attributes, context, exclusions)
%   This function parses a given attribute info structure and returns a 
%   containers.Map of valid attributes along with neurodata type info if it 
%   exists.
%
% Input Arguments:
%   filename   - The name of the file containing attributes.
%   attributes - The attributes to be parsed.
%   context    - The context (h5 location) in which the attributes are located.
%   exclusions - Attribute and group names to be excluded from the parsing.
%
% Output Arguments:
%   args - A containers.Map of all valid attributes.
%   type - A structure with type information (see io.getNeurodataTypeInfo)
%
% See also: io.getNeurodataTypeInfo

if nargin < 5
    reader = io.backend.BackendFactory.createReader(filename);
end

args = containers.Map;
type = io.getNeurodataTypeInfo(attributes);

if isempty(attributes)
    return;
end

names = {attributes.Name};

% We already got type information (if present), so we add type-specific 
% attributes to the exclusions before parsing the rest of the attribute list
exclusions.attributes = [exclusions.attributes, {'neurodata_type', 'namespace'}];

excludedMask = ismember(names, exclusions.attributes);
attributes(excludedMask) = [];
for i=1:length(attributes)
    attr = attributes(i);
    args(attr.Name) = reader.readAttributeValue(attr, context);
end
end
