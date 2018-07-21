function writeTable(fid, fullpath, data)
%check for references
if isstruct(data)
    names = fieldnames(data);
else %istable
    names = data.Properties.VariableNames;
end
numNames = length(names);

tid = io.getBaseType(class(data), data);

classes = cell(numNames, 1);
for i=1:numNames
    datum = data.(names{i});
    if iscellstr(datum)
        %pad cell string to match so data can be uniformally writable
        datum = io.padCellStr(datum);
        data.(names{i}) = datum;
    end
    classes{i} = class(datum);
end

refs_i = strcmp(classes, 'types.untyped.ObjectView') |...
    strcmp(classes, 'types.untyped.RegionView');

if any(refs_i)
    rawrefs = writeReferences(fid, data(:, refs_i));
    refnames = names(refs_i);
    for i=1:length(refnames)
        data.(refnames{i}) = rawrefs.(refnames{i});
    end
end

%needs to be a struct
if istable(data)
    numrows = height(data);
    data = table2struct(data, 'ToScalar', true);
end

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
h = height(obj_refs);
w = width(obj_refs);
col_data = cell(h, 1);
for i=1:w
    col_name = names{i};
    refcol = obj_refs.(col_name);
    for j=1:h
        ref = refcol(j);
        if iscell(ref) %if the number of rows is 1, then this value is not a cell.
            ref = ref{1};
        end
        col_data{j} = io.getRefData(fid, ref);
    end
    obj_refs.(col_name) = col_data;
end
end