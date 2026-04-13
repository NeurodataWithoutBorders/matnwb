function [args, type] = parseAttributes(filename, attributes, context, Blacklist, reader)
% parseAttributes - Parse an attribute info structure
%
% Syntax:
%   [args, type] = io.parseAttributes(filename, attributes, context, Blacklist)
%   This function parses a given attribute info structure and returns a 
%   containers.Map of valid attributes along with neurodata type info if it 
%   exists.
%
% Input Arguments:
%   filename   - The name of the file containing attributes.
%   attributes - The attributes to be parsed.
%   context    - The context (h5 location) in which the attributes are located.
%   Blacklist  - A list of attributes to be excluded from the parsing.
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
% attributes to the blacklist before parsing the rest of the attribute list
Blacklist.attributes = [Blacklist.attributes, {'neurodata_type', 'namespace'}];

blacklistMask = ismember(names, Blacklist.attributes);
attributes(blacklistMask) = [];
for i=1:length(attributes)
    attr = attributes(i);
    args(attr.Name) = reader.readAttributeValue(attr, context);
end
end
