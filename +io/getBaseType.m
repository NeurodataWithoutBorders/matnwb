function id = getBaseType(type, data)
if isa(data, 'table')
    %construct custom table
    classes = cell(size(data.Properties.VariableNames));
    sizes = zeros(size(classes));
    rawnames = cell(size(classes));
    for i=1:length(classes)
        datum = data.(data.Properties.VariableNames{i});
        if iscell(datum)
            datum = datum{1};
        end
        classes{i} = class(datum);
        switch classes{i}
            case {'char' 'types.untyped.RegionView'}
                %size of vlen string a pointer to region
                typesize = 16;
            case {'double' 'int64' 'uint64' 'types.untyped.ObjectView'}
                typesize = 8;
            case {'single' 'int32' 'uint32'}
                typesize = 4;
            otherwise
                keyboard;
        end
        sizes(i) = typesize;
        rawnames{i} = getRawType(classes{i});
    end
    
    id = H5T.create('H5T_COMPOUND', sum(sizes));
    offset = 0;
    for i=1:length(classes)
        if strcmp(rawnames{i}, 'H5T_C_S1')
            %if is string, make it variable length
            rawid = H5T.copy(rawnames{i});
            H5T.set_size(rawid, 'H5T_VARIABLE');
        else
            rawid = rawnames{i};
        end
        %insert columns into compound type
        H5T.insert(id, data.Properties.VariableNames{i}, offset, rawid);
        offset = offset + sizes(i);
    end
else
    id = getRawType(type);
    if strcmp(id, 'H5T_C_S1')
        id = H5T.copy(id);
        if iscellstr(data)
            tsize = max(cellfun('length', data));
        else
            tsize = size(data, 2);
        end
        H5T.set_size(id, tsize);
    end
end
end

function typename = getRawType(type)
switch type
    case 'types.untyped.ObjectView'
        typename = 'H5T_STD_REF_OBJ';
    case 'types.untyped.RegionView'
        typename = 'H5T_STD_REF_DSETREG';
    case {'char' 'cell'}
        typename = 'H5T_C_S1';
    case 'double'
        typename = 'H5T_NATIVE_DOUBLE';
    case 'int64'
        typename = 'H5T_NATIVE_LLONG';
    case 'uint64'
        typename = 'H5T_NATIVE_ULLONG';
    otherwise
        error('Type `%s` is not a support raw type', type);
end
end