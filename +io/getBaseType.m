function id = getBaseType(type, data)
id = getRawType(type);
switch id
    case 'H5T_COMPOUND'
        %create H5T_COMPOUND type with proper sizes
        if isstruct(data)
            variableNames = fieldnames(data);
        elseif istable(data)
            variableNames = data.Properties.VariableNames;
        else
            error('io.getBaseType only support `struct` or `table` types as H5T_COMPOUND');
        end
        
        numVariables = length(variableNames);
        %despite what it may seem, H5ML.get_constant_value returns a
        %double, but H5T.copy returns a `H5ML.id`.  So you will basically
        %be constantly juggling either char/id or double/id types.
        tids = cell(numVariables, 1);
        sizes = zeros(numVariables, 1);
        for i=1:numVariables
            datum = data.(variableNames{i});
            %recurse
            if iscell(datum) && ~iscellstr(datum)
                datum = datum{1};
            end
            tids{i} = io.getBaseType(class(datum), datum);
            sizes(i) = H5T.get_size(tids{i});
        end
        
        id = H5T.create('H5T_COMPOUND', sum(sizes));
        offset = 0;
        for i=1:numVariables
            %insert columns into compound type
            propname = variableNames{i};
            H5T.insert(id, propname, offset, tids{i});
            offset = offset + sizes(i);
            if isa(tids{i}, 'H5ML.id')
                %close if custom type id (errors if char base type)
                H5T.close(tids{i});
            end
        end
        H5T.pack(id);
    case 'H5T_C_S1'
        %modify id to set the proper size
        id = H5T.copy(id);
        if iscellstr(data)
            %if data is a cell array of str, then return the maximum size
            %The data must now be converted to char array evenly padded to
            %this maximum size
            tsize = max(cellfun('length', data));
        else
            tsize = size(data, 2);
        end
        if tsize <= 0
            tsize = 'H5T_VARIABLE';
        end
        H5T.set_size(id, tsize);
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
    case 'int32'
        typename = 'H5T_NATIVE_INT';
    case 'single'
        typename = 'H5T_NATIVE_FLOAT';
    case {'table', 'struct'}
        typename = 'H5T_COMPOUND';
    case 'logical'
        typename = 'H5T_NATIVE_HBOOL';
    otherwise
        error('Type `%s` is not a support raw type', type);
end
end