function writeCompound(fid, fullpath, data)
assert(isstruct(data) || istable(data) || isa(data, 'containers.Map'),...
    'io.writeCompound error: data must be a struct, table, or containers.Map');

%convert to a struct
if istable(data) || isa(data, 'containers.Map')
    if istable(data)
        names = data.Properties.VariableNames;
    else
        names = keys(data);
    end
    s = struct();
    for i=1:length(names)
        if istable(data)
            val = data.(names{i});
        else
            val = data(names{i});
        end
        s.(misc.str2validName(names{i})) = val;
    end
    data = s;
    names = fieldnames(data);
else
    %convert to scalar struct
    names = fieldnames(data);
    if ~isscalar(data)
        s = struct();
        for i=1:length(names)
            s.(names{i}) = {data.(names{i})};
        end
        data = s;
    end
end

%check for references and construct tid.
classes = cell(length(names), 1);
tids = cell(size(classes));
sizes = zeros(size(classes));
rows = zeros(size(classes));
for i=1:length(names)
    val = data.(names{i});
    assert(isvector(val),...
        'io.writeCompound error: data columns must be in a vector form');
    if ischar(val)
        rows(i) = 1;
    else
        rows(i) = length(val);
    end
    if iscell(val) && ~iscellstr(val)
        assert(all(cellfun('isclass', val, class(val{1}))),...
            'io.writeCompound error: data rows must be homogenous with respect to column');
        data.(names{i}) = [val{:}];
        val = val{1};
    end
    
    classes{i} = class(val);
    tids{i} = io.getBaseType(classes{i}, val);
    sizes(i) = H5T.get_size(tids{i});
end
numrows = unique(rows);
assert(isscalar(numrows),...
    'io.writeCompound error: data must have matching number of rows');

tid = H5T.create('H5T_COMPOUND', sum(sizes));
for i=1:length(names)
    %insert columns into compound type
    H5T.insert(tid, names{i}, sum(sizes(1:i-1)), tids{i});
end
%close custom type ids (errors if char base type)
isH5ml = tids(cellfun('isclass', tids, 'H5ML.id'));
for i=1:length(isH5ml)
    H5T.close(isH5ml{i});
end
%optimizes for type size
H5T.pack(tid);

ref_i = strcmp(classes, 'types.untyped.ObjectView') |...
    strcmp(classes, 'types.untyped.RegionView');

%transpose numeric column arrays to row arrays
% reference and str arrays are handled below
transposeNames = names(~ref_i);
for i=1:length(transposeNames)
    nm = transposeNames{i};
    val = data.(nm);
    if iscolumn(val)
        data.(nm) = val .';
    end
end

%attempt to convert raw reference information
refNames = names(ref_i);
for i=1:length(refNames)
    nm = refNames{i};
    data.(nm) = io.getRefData(fid, data.(nm)) .';
end

%convert all cellstr to multidim array
str_names = names(strcmp(classes, 'cell'));
for i=1:length(str_names)
    nm = str_names{i};
    dc = data.(nm);
    if all(cellfun('isempty', dc))
        data.(nm) = {''};
    else
        data.(nm) = cell2mat(dc);
    end
end

sid = H5S.create_simple(1, numrows, []);
did = H5D.create(fid, fullpath, tid, sid, 'H5P_DEFAULT');
H5D.write(did, tid, sid, sid, 'H5P_DEFAULT', data);
end