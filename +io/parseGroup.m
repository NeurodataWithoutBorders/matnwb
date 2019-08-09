function parsed = parseGroup(filename, info, blacklist)
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

%handle blacklist (which should be a Group)
for i=1:length(info.Groups)
    group = info.Groups(i);
    if strcmp(blacklist, group.Name)
        continue;
    end
    [~, gname] = io.pathParts(group.Name);
    subg = io.parseGroup(filename, group, blacklist);
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
        elided_gprops = elide(gprops, properties(typename));
        gprops = [gprops; elided_gprops];
    end
    %construct as kwargs and instantiate object
    kwargs = io.map2kwargs([attrprops; dsprops; gprops; lprops]);
    if isempty(root)
        %we are root
        parsed = NwbFile(kwargs{:});
        return;
    end
    parsed = eval([typename '(kwargs{:})']);
end
end

%NOTE: SIDE EFFECTS ALTER THE SET
function elided = elide(set, prop, prefix)
%given raw data representation, match to closest property.
% return a typemap of matching typeprops and their prop values to turn into kwargs
% depth first search through the set to construct a possible type prop
if nargin < 3
    prefix = '';
end
elided = containers.Map;
elidekeys = keys(set);
elidevals = values(set);
drop = false(size(elidekeys));
if ~isempty(prefix)
    potentials = strcat(prefix, '_', elidekeys);
else
    potentials = elidekeys;
end
for i=1:length(potentials)
    pvar = potentials{i};
    pvalue = elidevals{i};
    if isa(pvalue, 'containers.Map') || isa(pvalue, 'types.untyped.Set')
        if pvalue.Count == 0
            drop(i) = true;
            continue; %delete
        end
        leads = startsWith(prop, pvar);
        if any(leads)
            %since set has been edited, we bubble up deletion of the old keys.
            subset = elide(pvalue, prop(leads), pvar);
            elided = [elided; subset];
            if pvalue.Count == 0
                drop(i) = true;
            elseif any(strcmp(pvar, prop))
                elided(pvar) = pvalue;
                drop(i) = true;
            else
                warning('Unable to match property `%s` under prefix `%s`',...
                    pvar, prefix);
            end
        end
    elseif any(strcmp(pvar, prop))
        elided(pvar) = pvalue;
        drop(i) = true;
    end
end
remove(set, elidekeys(drop)); %delete all leftovers that were yielded
end