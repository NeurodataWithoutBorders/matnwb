function value = coerceType(name, type, value)
%COERCETYPE attempts to coerce the value to the given type.
is_numeric = any(strcmpi(type, {'single', 'double', 'logical', 'numeric'}))...
        || startsWith(type, {'int', 'uint' 'float'});
if isstruct(type)
    value = coerce_compound(value, type);
elseif is_numeric(type)
    value = coerce_numeric(value, type);
elseif strcmp(type, 'isodatetime')
    value = coerce_isodatetime(value);
end
end

function Compound = coerce_compound(Compound, Type)
fields = fieldnames(Type);
for i = 1:length(fields)
    property = fields{i};
end

    function value = get_column(Container, key)
        is_struct_of_arrays = isstruct(Container) && ~isscalar(Container);
        is_array_of_structs = isstruct(Container) && isscalar(Container);
        if is_struct_of_arrays || istable(Container)
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

    function set_column(Container, key, value)
        
    end
end

function date_time = coerce_isodatetime(date_time)
addpath(fullfile(fileparts(which('NwbFile')), 'external_packages', 'datenum8601'));

% convert to datetime arrays
if ischar(date_time) || iscellstr(date_time)
    if ischar(date_time)
        date_time = {date_time};
    end
    
    datevals = cell(size(date_time));
    % one of:
    % +-hh:mm
    % +-hhmm
    % +-hh
    % Z
    tzre_pattern = '(?:[+-]\d{2}(?::?\d{2})?|Z)$';
    for i = 1:length(date_time)
        dnum = datenum8601(date_time{i});
        
        tzre_match = regexp(date_time{i}, tzre_pattern, 'once');
        if isempty(tzre_match)
            tz = 'local';
        else
            tz = date_time{i}(tzre_match:end);
            if strcmp(tz, 'Z')
                tz = 'UTC';
            end
        end
        datevals{i} = ...
            datetime(dnum(1), 'TimeZone', tz, 'ConvertFrom', 'datenum');
    end
    date_time = datevals;
end

if isdatetime(date_time)
    date_time = {date_time};
end

for i=1:length(date_time)
    if isempty(date_time{i}.TimeZone)
        date_time{i}.TimeZone = 'local';
    end
    date_time{i}.Format = 'yyyy-MM-dd''T''HH:mm:ss.SSSSSSZZZZZ';
end

if isscalar(date_time)
    date_time = date_time{1};
end
end

function numeric = coerce_numeric(numeric, type)
if startsWith(type, 'float')
    % Compatibility with PyNWB
    %     if strcmp(type, 'float32')
    %         val = single(val);
    %     else
    numeric = double(numeric);
    %     end
elseif startsWith(type, 'int') || startsWith(type, 'uint')
    if strcmp(type, 'int')
        numeric = int32(numeric);
    elseif strcmp(type, 'uint')
        numeric = uint32(numeric);
    else
        numeric = feval(type, numeric);
    end
elseif strcmp(type, 'numeric') && ~isnumeric(numeric)
    numeric = double(numeric);
elseif strcmp(type, 'bool')
    numeric = logical(numeric);
end
end
