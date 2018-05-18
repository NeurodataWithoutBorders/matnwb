function parsed = parseGroup(filename, info)
% NOTE, group name is in path format so we need to parse that out.
% parsed is either a containers.Map containing properties mapped to values OR a
% typed value
links = containers.Map;
refs = containers.Map;
[~, root, ~] = io.pathParts(info.Name);
[props, typename] = io.parseAttributes(info.Attributes);

%parse datasets
for i=1:length(info.Datasets)
    ds_info = info.Datasets(i);
    fp = [info.Name '/' ds_info.Name];
    ds = io.parseDataset(filename, ds_info, fp);
    if isa(ds, 'containers.Map')
        props = [props; ds];
    else
        props(ds_info.Name) = ds;
    end
end

%parse subgroups
for i=1:length(info.Groups)
    g_info = info.Groups(i);
    [~, gname, ~] = io.pathParts(g_info.Name);
    subg = io.parseGroup(filename, g_info);
    props(gname) = subg;
end

%create link stub
for i=1:length(info.Links)
    l = info.Links(i);
    fpname = [info.Name '/' l.Name];
    switch l.Type
        case 'soft link'
            lnk = types.untyped.SoftLink(l.Value{1});
        otherwise %todo assuming external link here
            lnk = types.untyped.ExternalLink(l.Value{:});
    end
    props(l.Name) = lnk;
end

if isempty(typename)
    parsed = types.untyped.Set(props);
    
    if isempty(parsed)
        %special case where a directory is simply empty.  Return itself but
        %empty
        parsed(root) = [];
    end
else
    %elide properties which require elision
    propnames = keys(props);
    typeprops = setdiff(properties(typename), propnames);
    elided_typeprops = typeprops(startsWith(typeprops, propnames));
    for i=1:length(elided_typeprops)
        etp = elided_typeprops{i};
        props(etp) = elide(etp, props);
    end
    
    %construct as kwargs and instantiate object
    kwargs = io.map2kwargs(props);
    if isempty(root)
        %we are root
        parsed = nwbfile(kwargs{:});
        return;
    end
    parsed = eval([typename '(kwargs{:})']);
end
end

function set = elide(propname, elideset)
%given propname and a nested set, elide and return flattened set
set = elideset;
prefix = '';
while ~strcmp(prefix, propname)
    ekeys = keys(set);
    found = false;
    for i=1:length(ekeys)
        ek = ekeys{i};
        if isempty(prefix)
            pek = ek;
        else
            pek = [prefix '_' ek];
        end
        if startsWith(propname, pek)
            if isa(set, 'containers.Map')
                set = set(ek);
            else
                set = set.get(ek);
            end
            prefix = pek;
            found = true;
            break;
        end
    end
    if ~found
        set = [];
        return;
    end
end
end