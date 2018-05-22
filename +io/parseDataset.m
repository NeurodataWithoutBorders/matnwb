function parsed = parseDataset(filename, info, fullpath)
%typed and untyped being container maps containing type and untyped datasets
% the maps store information regarding information and stored data
% NOTE, dataset name is in path format so we need to parse that out.
name = info.Name;

%check if typed and parse attributes
[attrargs, typename] = io.parseAttributes(info.Attributes);

fid = H5F.open(filename);
did = H5D.open(fid, fullpath);
props = attrargs;
datatype = info.Datatype;

if isempty(typename) %a Group's properties
    parsed = containers.Map;
    afields = keys(attrargs);
    if ~isempty(afields)
        anames = strcat(name, '_', afields);
        parsed = [parsed; containers.Map(anames, attrargs.values(afields))];
    end
    
    if strcmp(info.Datatype.Class, 'H5T_STRING') || ~strcmp(info.Dataspace.Type, 'simple')
        data = H5D.read(did);
        if iscellstr(data)
            data = data{1};
        end
    else
        data = types.untyped.DataStub(filename, fullpath);
    end
    
    parsed(name) = data;
    H5D.close(did);
    H5F.close(fid);
    return;
end

if strcmp(datatype.Class, 'H5T_REFERENCE')
    props('data') = parseReference(did, datatype.Type, H5D.read(did));
elseif strcmp(datatype.Class, 'H5T_COMPOUND')
    compound = datatype.Type.Member;
    data = H5D.read(did);
    if isempty(data)
        props('data') = [];
    else
        for j=1:length(compound)
            comp = compound(j);
            if strcmp(comp.Datatype.Class, 'H5T_REFERENCE')
                refnames = data.(comp.Name);
                reflist = cell(size(refnames, 2), 1);
                for k=1:size(refnames,2)
                    r = refnames(:,k);
                    reflist{k} = parseReference(did, comp.Datatype.Type, r);
                end
                data.(comp.Name) = reflist;
            end
        end
        props('data') = struct2table(data);
    end
else
    props('data') = types.untyped.DataStub(filename, fullpath);
end
kwargs = io.map2kwargs(props);
parsed = eval([typename '(kwargs{:})']);

H5D.close(did);
H5F.close(fid);
end

function refobj = parseReference(did, type, data)
target = H5R.get_name(did, type, data);
region = [];
if strcmp(type, 'H5R_DATASET_REGION')
    sid = H5R.get_region(did, type, data);
    [start, finish] = H5S.get_select_bounds(sid);
    H5S.close(sid);
    region = [start finish];
end

if isempty(region)
    refobj = types.untyped.ObjectView(target);
else
    refobj = types.untyped.RegionView(target, region);
end
end