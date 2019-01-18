function parsed = parseGroup(filename, info)
% NOTE, group name is in path format so we need to parse that out.
% parsed is either a containers.Map containing properties mapped to values OR a
% typed value
links = containers.Map;
refs = containers.Map;
[~, root] = io.pathParts(info.Name);
[attrprops, typename] = io.parseAttributes(filename, info.Attributes, info.Name);

%parse datasets
dsprops = containers.Map;
for i=1:length(info.Datasets)
    ds_info = info.Datasets(i);
    fp = [info.Name '/' ds_info.Name];
    ds = io.parseDataset(filename, ds_info, fp);
    if isa(ds, 'containers.Map')
        dsprops = [dsprops; ds];
    else
        dsprops(ds_info.Name) = ds;
    end
end

%parse subgroups
gprops = containers.Map;
for i=1:length(info.Groups)
    g_info = info.Groups(i);
    [~, gname] = io.pathParts(g_info.Name);
    subg = io.parseGroup(filename, g_info);
    gprops(gname) = subg;
end

%create link stub
lprops = containers.Map;
for i=1:length(info.Links)
    l = info.Links(i);
    fpname = [info.Name '/' l.Name];
    switch l.Type
        case 'soft link'
            lnk = types.untyped.SoftLink(l.Value{1});
        otherwise %todo assuming external link here
            lnk = types.untyped.ExternalLink(l.Value{:});
    end
    lprops(l.Name) = lnk;
end

if isempty(typename)
    parsed = types.untyped.Set([attrprops; dsprops; gprops; lprops]);
    
    if isempty(parsed)
        %special case where a directory is simply empty.  Return itself but
        %empty
        parsed(root) = [];
    end
else
    if gprops.Count > 0
        %elide group properties
        propnames = keys(gprops);
        typeprops = setdiff(properties(typename), propnames);
        elided_typeprops = typeprops(startsWith(typeprops, propnames));
        gprops = [gprops; elide(gprops, elided_typeprops)];
        %remove all properties that are embedded sets (sets within sets)
        propnames = keys(gprops);
        propvals = values(gprops);
        valueSetIdx = cellfun('isclass', propvals, 'types.untyped.Set');
        setNames = propnames(valueSetIdx);
        setValues = propvals(valueSetIdx);
        for i=1:length(setValues)
            nlevel = setValues{i};
            nlevelkeys = keys(nlevel);
            deepsetIdx = cellfun('isclass', values(nlevel), 'types.untyped.Set');
            nlevel.delete(nlevelkeys(deepsetIdx));
            if nlevel.Count == 0
                remove(gprops, setNames{i}); %delete this set too if it's empty
            end
        end
    end
    %construct as kwargs and instantiate object
    kwargs = io.map2kwargs([attrprops; dsprops; gprops; lprops]);
    if isempty(root)
        %we are root
        parsed = nwbfile(kwargs{:});
        return;
    end
    parsed = eval([typename '(kwargs{:})']);
end
end

function set = elide(elideset, elided_typeprops, prefix)
%given raw data representation, match to closest property.
% return a typemap of matching typeprops and their prop values to turn into kwargs
% depth first search through the set to construct a possible type prop
set = containers.Map;
if nargin < 3
    prefix = '';
end
elidekeys = keys(elideset);
elidevals = values(elideset);
constrained = types.untyped.Set();
if ~isempty(prefix)
    potentials = strcat(prefix, '_', elidekeys);
else
    potentials = elidekeys;
end
for i=1:length(potentials)
    pvar = potentials{i};
    pvalue = elidevals{i};
    if isa(pvalue, 'containers.Map') || isa(pvalue, 'types.untyped.Set')
        if isa(elideset, 'containers.Map')
            nextSet = elideset(elidekeys{i});
        else % types.untyped.Set
            nextSet = elideset.get(elidekeys{i});
        end
        leads = startsWith(elided_typeprops, pvar);
        if ~any(leads)
            %this group probably doesn't have any elided values in it.
            continue;
        end
        set = [set; elide(nextSet, elided_typeprops(leads), pvar)];
    elseif any(strcmp(pvar, elided_typeprops))
        set(pvar) = pvalue;
    elseif ~isempty(prefix) %attempt to combine into a Set
        constrained.set(elidekeys{i}, pvalue);
    end
end
if constrained.Count > 0
    set(prefix) = constrained;
end
end