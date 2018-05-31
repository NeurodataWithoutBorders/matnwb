function writeTable(fid, fullpath, data)
%check for references
names = data.Properties.VariableNames;
classes = cell(size(names));
types = cell(size(names));
sizes = zeros(size(names));
for i=1:length(classes)
    datum = data.(names{i});
    if iscell(datum) && ~iscellstr(datum)
        datum = datum{1};
    end
    
    if iscellstr(datum)
        %for the sake of getBaseType, we pretend cell strings are char
        %types
        typeclass = 'char';
    else
        typeclass = class(datum);
    end
    type = io.getBaseType(typeclass, datum);
    typesize = H5T.get_size(type);
    if iscellstr(datum)
        %pad cell string to match so data can be uniformally writable
        datum = io.padCellStr(datum, typesize);
        data.(data.Properties.VariableNames{i}) = datum;
    end
    sizes(i) = typesize;
    classes{i} = class(datum);
    types{i} = type;
end

refs_i = strcmp(classes, 'types.untyped.ObjectView') |...
    strcmp(classes, 'types.untyped.RegionView');

if any(refs_i)
    data(:, refs_i) = writeReferences(fid, data(:, refs_i));
end

%define data type
tid = H5T.create('H5T_COMPOUND', sum(sizes));
offset = 0;
for i=1:length(names)
    H5T.insert(tid, names{i}, offset, types{i});
    offset = offset + sizes(i);
end
%needs to be a struct
numrows = height(data);
data = table2struct(data, 'ToScalar', true);

%struct is ordered columnwise but H5D requires rowwise arrays to write
%column data.  So we transpose the data before further conversion
for i=1:length(names)
    data.(names{i}) = data.(names{i}) .';
end

%convert all cells to matrices
cell_i = strcmp(classes, 'cell') | refs_i;
if any(cell_i)
    str_names = names(cell_i);
    for i=1:length(str_names)
        name = str_names{i};
        data.(name) = cell2mat(data.(name));
    end
end

sid = H5S.create_simple(1, numrows, []);
did = H5D.create(fid, fullpath, tid, sid, 'H5P_DEFAULT');
H5D.write(did, tid, sid, sid, 'H5P_DEFAULT', data);
end

function obj_refs = writeReferences(fid, obj_refs)
%maps obj_refs from ref classes to HDF5 writable ref types
names = obj_refs.Properties.VariableNames;
col_data = cell(size(obj_refs, 1), 1);
for i=1:size(obj_refs, 2)
    col_name = names{i};
    refcol = obj_refs.(col_name);
    for j=1:size(obj_refs, 1)
        ref = refcol{j};
        col_data{j} = io.getRefData(fid, ref);
    end
    obj_refs.(col_name) = col_data;
end
end