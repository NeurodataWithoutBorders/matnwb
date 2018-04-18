function [parsed, links, refs] = parseGroup(filename, info)
% NOTE, group name is in path format so we need to parse that out.
% parsed is either a containers.Map containing properties mapped to values OR a
% typed value
links = [];
refs = containers.Map;
[~, root] = io.pathParts(info.Name);
[props, typename] = io.parseAttributes(info.Attributes);

%parse datasets
for i=1:length(info.Datasets)
    ds_info = info.Datasets(i);
    fp = [info.Name '/' ds_info.Name];
    [ds, dsrefs] = io.parseDataset(filename, ds_info, fp);
    props = [props; ds];
    refs = [refs; dsrefs];
end

%parse links if present
for i=1:length(info.Links)
    links = [links io.parseLink(info.Links)];
end

%parse subgroups
for i=1:length(info.Groups)
    g_info = info.Groups(i);
    [~, gname] = io.pathParts(g_info.Name);
    [subg, glinks, grefs] = io.parseGroup(filename, g_info);
    props(gname) = subg;
    links = [links glinks];
    refs = [refs; grefs];
end

if isempty(typename)
    parsed = containers.Map;
    keyboard;
else
    %construct as kwargs and instantiate object
    
    if isempty(root)
        %we are root
        parsed = types.core.NWBFile;
        return;
    end
end
end