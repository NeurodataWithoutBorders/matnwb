function parsed = parseDataset(filename, info, fullpath, Blacklist)
%typed and untyped being container maps containing type and untyped datasets
% the maps store information regarding information and stored data
% NOTE, dataset name is in path format so we need to parse that out.
name = info.Name;

%check if typed and parse attributes
[attrargs, typename] = io.parseAttributes(filename, info.Attributes, fullpath, Blacklist);

fid = H5F.open(filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
did = H5D.open(fid, fullpath);
props = attrargs;
datatype = info.Datatype;
dataspace = info.Dataspace;

parsed = containers.Map;
afields = keys(attrargs);
if ~isempty(afields)
    anames = strcat(name, '_', afields);
    parsed = [parsed; containers.Map(anames, attrargs.values(afields))];
end

% loading h5t references are required
% unfortunately also a bottleneck
if strcmp(datatype.Class, 'H5T_REFERENCE')
    tid = H5D.get_type(did);
    data = io.parseReference(did, tid, H5D.read(did));
    H5T.close(tid);
elseif ~strcmp(dataspace.Type, 'simple')
    data = H5D.read(did);
    if iscellstr(data) && 1 == length(data)
        %pynwb will use variable string lengths which are read in as bulky
        %cellstr.  We don't like that so convert to char arrays
        data = data{1};
    elseif ischar(data)
        data = data .';
        datadim = size(data);
        if datadim(1) > 1
            %multidimensional strings should be using cell str
            data = strtrim(mat2cell(data, ones(datadim(1), 1), datadim(2)));
        end
    end
elseif strcmp(dataspace.Type, 'simple') && any(dataspace.Size == 0)
    data = [];
else
    data = types.untyped.DataStub(filename, fullpath);
end

if isempty(typename)
    %untyped group
    parsed(name) = data;
else
    props('data') = data;
    kwargs = io.map2kwargs(props);
    parsed = eval([typename '(kwargs{:})']);
end
H5D.close(did);
H5F.close(fid);
end