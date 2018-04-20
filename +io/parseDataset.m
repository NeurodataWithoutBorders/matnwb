function [parsed, refs] = parseDataset(filename, info, fullpath)
%typed and untyped being container maps containing type and untyped datasets
% the maps store information regarding information and stored data
% NOTE, dataset name is in path format so we need to parse that out.
refs = containers.Map;
name = info.Name;

%check if typed and parse attributes
[attrargs, typename] = io.parseAttributes(info.Attributes);

if isempty(typename) %a Group's properties
    parsed = containers.Map;
    afields = keys(attrargs);
    for j=1:length(afields)
        attr = afields{j};
        parsed([name '_' attr]) = attrargs(attr);
    end
    data = h5read(filename, fullpath);
    if iscellstr(data)
        data = data{1};
    elseif iscell(data)
        keyboard;
    end
    parsed(name) = data;
    return;
end
% given name, either a:
%   direct reference (ElectrodeTableRegion)
%   compound data w/ reference (ElectrodeTable)
%   All other cases do not exist in this current schema.
props = attrargs;

fid = H5F.open(filename);
did = H5D.open(fid, fullpath);
data = H5D.read(did); %this way, references are not automatically resolved

datatype = info.Datatype;
if strcmp(datatype.Class, 'H5T_REFERENCE')
    [path, reg] = parseReference(did, datatype.Type, data);
    refs([fullpath '/ref']) = struct('path', path, 'region', reg);
    props('ref') = [];
elseif strcmp(datatype.Class, 'H5T_COMPOUND')
    t = table;
    compound = datatype.Type.Member;
    for j=1:length(compound)
        comp = compound(j);
        if strcmp(comp.Datatype.Class, 'H5T_REFERENCE')
            refnames = data.(comp.Name);
            reflist = repmat(struct('path', [], 'region', []), size(refnames));
            for k=1:size(refnames,2)
                r = refnames(:,k);
                [path, reg] = parseReference(did, comp.Datatype.Type, r);
                reflist(k).path = path;
                reflist(k).region = reg;
            end
            refs([fullpath '/' info.Name '.' comp.Name]) = reflist;
            %for some reason, raw references are stored transposed.
            data.(comp.Name) = cell(size(refnames, 2), 1);
        end
    end
    props('table') = struct2table(data);
else
    keyboard;
end
kwargs = io.map2kwargs(props);
parsed = eval([typename '(kwargs{:})']);

H5D.close(did);
H5F.close(fid);
end

function [target, region] = parseReference(did, type, data)
target = H5R.get_name(did, type, data);
region = [];
if strcmp(type, 'H5R_DATASET_REGION')
    sid = H5R.get_region(did, type, data);
    [start, finish] = H5S.get_select_bounds(sid);
    H5S.close(sid);
    region = [start finish];
end
end
