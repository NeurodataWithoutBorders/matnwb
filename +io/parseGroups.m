function [parsed, links, refs] = parseGroups(filename, group_info)
% NOTE, group name is in path format so we need to parse that out.
% parsed is either a containers.Map containing properties mapped to values OR a
% typed value
parsed = [];
links = {};
refs = containers.Map;

%check if typed and parse attributes

%parse datasets

%parse subgroups
end