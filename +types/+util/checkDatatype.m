function checkDatatype(name, type, val)
errid = 'MATNWB:INVALIDTYPE';

if isstruct(type)
    validate_compound(name, type, val, errid);
else
    if isempty(val) || isa(val, 'types.untyped.SoftLink')
        return;
    end
    
    unwrapped = unwrap_value(val);
    if iscell(unwrapped) && isempty(unwrapped)
        return;
    end
    
    is_numeric = any(strcmpi(type, {'single', 'double', 'logical', 'numeric'}))...
        || startsWith(type, {'int', 'uint' 'float'});
    if is_numeric
        assert(isnumeric(unwrapped) || islogical(unwrapped), errid, errmsg);
    elseif strcmp(type, 'isodatetime')
        is_string = ischar(unwrapped) || iscellstr(unwrapped);
        is_datetime = isdatetime(unwrapped)...
            || (iscell(unwrapped) && all(cellfun('isclass', unwrapped, 'datetime')));
        assert(is_string || is_datetime, errid, errmsg);
    elseif strcmp(type, 'char')
        assert(ischar(unwrapped) || iscellstr(unwrapped),...
            errid, '`%s` must be a character array.', name);
    else % class, ref, or link
        validate_user_type(name, unwrapped, type, errid);
    end
end
end

function unwrapped = unwrap_value(value)
if isa(value, 'types.untyped.DataStub')
    %grab first element and check
    if any(value.dims == 0)
        unwrapped = value.load();
    else
        unwrapped = value.load(1);
    end
elseif isa(value, 'types.untyped.Anon')
    unwrapped = value.value;
elseif isa(value, 'types.untyped.ExternalLink')...
        && ~strcmp(type, 'types.untyped.ExternalLink')
    is_non_hdf5_file = isempty(value.path);
    if is_non_hdf5_file
        % cannot guarantee date type from raw files
        unwrapped = {};
    else
        % unwrap again in case it's a datastub
        unwrapped = unwrap_value(value.deref());
    end
else
    unwrapped = value;
end
end

function validate_compound(name, Type, Container, errid)
assert(isstruct(Container) || istable(Container) || isa(Container, 'containers.Map'), ...
    errid, 'Compound Type must be a struct, table, or a containers.Map');

is_table = istable(Container);
is_struct = isstruct(Container);
is_struct_of_arrays = is_struct && isscalar(Container);
is_array_of_structs = is_struct && ~isscalar(Container);
fields = fieldnames(Type);

if is_array_of_structs
    validate_array_of_structs(Container, Type);
end

validate_container_shape(Container, fields);
for i = 1:length(fields)
    field_name = fields{i};
    sub_property = [name '.' field_name];
    type_name = Type.(field_name);
    
    sub_value = get_column(Container, field_name);
    types.util.checkDatatype(sub_property, type_name, sub_value);
end

    function validate_container_shape(Container, fields)
        if is_table || isempty(Container)
            % tables already keep shape so don't bother.
            % same with empty containers (does not cover structs of arrays)
            return;
        end
        
        column_lengths = zeros(length(fields),1);
        for field_i = 1:length(fields)
            column = get_column(Container, fields{field_i});
            assert(isvector(column),...
                errid,...
                ['types.util.checkDtype: struct of arrays as a compound type ',...
                'cannot have multidimensional data in their fields.  Field data ',...
                'shape must be scalar or vector to be valid.']);
            column_lengths(field_i) = length(column);
        end
        column_lengths = unique(column_lengths);
        assert(isscalar(column_lengths),...
            errid,...
            ['struct of arrays as a compound type ',...
            'contains mismatched number of elements with unique sizes: [%s].  ',...
            'Number of elements for each struct field must match to be valid.'], ...
            num2str(column_lengths));
    end

    function validate_array_of_structs(Rows, Type)
        if isempty(Rows)
            return;
        end
        % check if the types are the same
        for field_i = 1:length(fields)
            field_name = fields{field_i};
            values = {Rows.(field_name)};
            type = Type.(field_name);
            is_valid_class = all(cellfun('isclass', values, type));
            is_valid_shape = all(cellfun('prodofsize', values) == 1);
            is_valid = is_valid_class && is_valid_shape;
            assert(iscellstr(values) || is_valid,...
                errid,...
                '%s.%s Expecting class %s, got %s',...
                name,...
                field_name,...
                type,...
                class(values{1}));
        end
    end

    function value = get_column(Container, key)
        if is_struct_of_arrays || is_table
            value = Container.(key);
        elseif is_array_of_structs
            raw_values = {Container.(key)};
            if iscellstr(raw_values)
                value = raw_values;
            else
                value = [raw_values{:}];
            end
        else % is map
            value = Container(key);
        end
    end
end

function validate_user_type(name, value, type, errid)
persistent WHITELIST;
if isempty(WHITELIST)
    WHITELIST = {...
        'types.untyped.ExternalLink'...
        'types.untyped.SoftLink'...
        };
end

if iscell(value)
    valid_class_mask = cellfun('isclass', value, type);
    check_subclass_indices = find(~valid_class_mask);
    for i = 1:length(check_subclass_indices)
        idx = check_subclass_indices(i);
        assert(isa(value{idx}, type),...
            errid, '`%s` must be a `%s`', name, type);
    end
else
    is_whitelisted = any(strcmp(class(value), WHITELIST));
    assert(isa(value, type) || is_whitelisted,...
        errid, '`%s` must be a `%s` or some link', name, type);
end
end