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
        else
            data = data .';
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
        datatypes = [compound.Datatype];
        classes = {datatypes.Class};
        dtTypes = {datatypes.Type}; %struct or char array
        ref_i = strcmp(classes, 'H5T_REFERENCE');
        char_i = strcmp(classes, 'H5T_STRING');
        %Strings should be the only type whose type is not a char array
        char_types = [dtTypes{char_i}];
        %if length is an absolute value, then matlab treats it as a char
        %array instead of a cell array.  We only care about transposing
        %char arrays
        char_i(char_i) = ~strcmp({char_types.Length}, 'H5T_VARIABLE');
        propnames = {compound.Name};
        if any(ref_i)
            %resolve references
            refPropNames = propnames(ref_i);
            refTypes = dtTypes(ref_i);
            for j=1:length(refPropNames)
                rpname = refPropNames{j};
                refdata = data.(rpname);
                reflist = cell(size(refdata, 2), 1);
                for k=1:size(refdata, 2)
                    r = refdata(:,k);
                    reflist{k} = parseReference(did, refTypes{j}, r);
                end
                data.(rpname) = reflist;
            end
        end
        
        if any(char_i)
            %transpose character arrays because they are column-ordered
            %when read
            charPropNames = propnames(char_i);
            for j=1:length(charPropNames)
                cpname = charPropNames{j};
                data.(cpname) = data.(cpname) .';
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
mode = '';
if strcmp(type, 'H5R_DATASET_REGION')
    sid = H5R.get_region(did, type, data);
    sel_type = H5S.get_select_type(sid);
    switch sel_type
        case {H5ML.get_constant_value('H5S_SEL_POINTS')...
                H5ML.get_constant_value('H5S_SEL_HYPERSLABS')}
            %the method for grabbing relevant points are exactly the same
            if sel_type == H5ML.get_constant_value('H5S_SEL_POINTS')
                getnum = @H5S.get_select_elem_npoints;
                getlist = @H5S.get_select_elem_pointlist;
                mode = 'point';
            else
                getnum = @H5S.get_select_hyper_nblocks;
                getlist = @H5S.get_select_hyper_blocklist;
                mode = 'block';
            end
            
            nSelections = getnum(sid);
            region = cell(1, nSelections);
            for i=1:nSelections
                region{i} = 1 + getlist(sid, i-1, 1);
            end
        case H5ML.get_constant_value('H5S_SEL_ALL')
            region = {};
            mode = 'all';
        case H5ML.get_constant_value('H5S_SEL_NONE')
            region = {};
            mode = 'none';
    end
    H5S.close(sid);
end

if isempty(mode)
    refobj = types.untyped.ObjectView(target);
else
    refobj = types.untyped.RegionView(target, region, mode);
end
end