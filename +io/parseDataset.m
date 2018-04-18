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
props('associated_nwbfile') = filename;

fid = H5F.open(filename);
did = H5D.open(fid, fullpath);
data = H5D.read(did); %this way, references are not automatically resolved

datatype = info.Datatype;
if strcmp(datatype.Class, 'H5T_REFERENCE')
    reftype = datatype.Type;
    switch reftype
        case 'H5R_OBJECT'
            %TODO when included in schema
        case 'H5R_DATASET_REGION'
            sid = H5R.get_region(did, reftype, data);
            [start, finish] = H5S.get_select_bounds(sid);
            props('target') = H5R.get_name(did, reftype, data);
            props('region') = [start+1 finish];
            H5S.close(sid);
    end
elseif strcmp(datatype.Class, 'H5T_COMPOUND')
    t = table;
    compound = datatype.Type.Member;
    isref = logical(size(compound));
    for j=1:length(compound)
        comp = compound(j);
        if strcmp(comp.Datatype.Class, 'H5T_REFERENCE')
            isref(j) = true;
        end
    end
end
kwargs = io.map2kwargs(props);
parsed = eval([typename '(kwargs{:})']);

H5D.close(did);
H5F.close(fid);
end