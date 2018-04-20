function [parsed, links, refs] = parseGroup(filename, info)
% NOTE, group name is in path format so we need to parse that out.
% parsed is either a containers.Map containing properties mapped to values OR a
% typed value
links = containers.Map;
refs = containers.Map;
[~, root] = io.pathParts(info.Name);
[props, typename] = io.parseAttributes(info.Attributes);
hasTypes = false;

%parse datasets
for i=1:length(info.Datasets)
    ds_info = info.Datasets(i);
    fp = [info.Name '/' ds_info.Name];
    [ds, dsrefs] = io.parseDataset(filename, ds_info, fp);
    if isa(ds, 'containers.Map')
        props = [props; ds];
    else
        props(ds_info.Name) = ds;
        hasTypes = true;
    end
    
    refs = [refs; dsrefs];
end

%parse subgroups
for i=1:length(info.Groups)
    g_info = info.Groups(i);
    [~, gname] = io.pathParts(g_info.Name);
    [subg, glinks, grefs] = io.parseGroup(filename, g_info);
    if isa(subg, 'containers.Map')
        props = [props; subg];
    else
        props(gname) = subg;
        hasTypes = true;
    end
    
    links = [links; glinks];
    refs = [refs; grefs];
end

%parse links and add to map of links
for i=1:length(info.Links)
    l = info.Links(i);
    fpname = [info.Name '/' l.Name];
    props(l.Name) = [];
    links([info.Name '/' l.Name]) = l;
    hasTypes = true;
end

if isempty(typename)
    %immediately elide prefix all property names with this but only if there are
    %no typed objects in it.
    propnames = keys(props);
    if hasTypes
        parsed = containers.Map({root}, {props});
    else
        parsed = containers.Map;
        for i=1:length(propnames)
            pnm = propnames{i};
            p = props(pnm);
            parsed([root '_' pnm]) = p;
        end
    end
    
    if isempty(parsed)
        %special case where a directory is simply empty.  Return itself but
        %empty
        parsed(root) = [];
    end
else
    %construct as kwargs and instantiate object
    kwargs = io.map2kwargs(props);
    if isempty(root)
        %we are root
        parsed = types.core.NWBFile(kwargs{:});
        return;
    end
    parsed = eval([typename '(kwargs{:})']);
end
end