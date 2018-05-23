function refs = writeTable(fid, fullpath, data, refs)
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
        typeclass = 'char';
    else
        typeclass = class(datum);
    end
    
    type = io.getBaseType(typeclass, datum);
    typesize = H5T.get_size(type);
    if iscellstr(datum)
        datum = io.padCellStr(datum, typesize);
        data.(data.Properties.VariableNames{i}) = datum;
    end
    sizes(i) = typesize;
    classes{i} = typeclass;
    types{i} = type;
end

refs_i = strcmp(classes, 'types.untyped.ObjectView') |...
    strcmp(classes, 'types.untyped.RegionView');
%grab ref data if they exist.  Otherwise, assign zeros and do it on second
%round.
if any(refs_i)
    [data(:, refs_i), unresolved] = writeReferences(fid, data(:, refs_i));
    if ~isempty(unresolved)
        refs(fullpath) = unresolved;
    end
end

%define data type
tid = H5T.create('H5T_COMPOUND', sum(sizes));
offset = 0;
for i=1:length(names)
    H5T.insert(tid, names{i}, offset, types{i});
    offset = offset + sizes(i);
end

sid = H5S.create_simple(1, size(data, 1), []);
did = H5D.create(fid, fullpath, tid, sid, 'H5P_DEFAULT');

%needs to be a struct
data = table2struct(data, 'ToScalar', true);

%convert all cells to multidim arrays (strings and refs)
cell_i = strcmp(classes, 'char') | refs_i;
if any(cell_i)
    str_names = names(cell_i);
    for i=1:length(str_names)
        name = str_names{i};
        data.(name) = cell2mat(data.(name));
    end
end

H5D.write(did, tid, sid, sid, 'H5P_DEFAULT', data);
%     table2struct(data, 'ToScalar', true));
end

function [obj_refs, unresolved] = writeReferences(fid, obj_refs)
unresolved = containers.Map;
names = obj_refs.Properties.VariableNames;
col_data = cell(size(obj_refs, 1), 1);
for i=1:size(obj_refs, 2)
    col_name = names{i};
    refcol = obj_refs.(col_name);
    for j=1:size(obj_refs, 1)
        ref = refcol{j};
        ref_data = io.getRefData(fid, ref);
        if ~any(ref_data) %that is, all zeros indicating failure
            if ~isKey(unresolved, col_name)
                unresolved(col_name) = cell(size(col_data));
            end
            unresolvedColumn = unresolved(col_name);
            unresolvedColumn{j} = ref.path;
            unresolved(col_name) = unresolvedColumn;
        end
        col_data{j} = ref_data;
    end
    obj_refs.(col_name) = col_data;
end
end